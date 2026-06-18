//
//  SearchViewModel.swift
//  RepoExplorer
//
//  Drives the search screen: debounced query handling, networking, and view state.
//

import Foundation
import Observation

/// `@MainActor` confines all UI state to the main actor (no main-thread violations, no data races
/// on the state). It is intentionally NOT `Sendable` — actor isolation is the safe alternative;
/// values that cross actor boundaries (the model results) are immutable `Sendable` structs.
@MainActor
@Observable
final class SearchViewModel {
    enum Status: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    /// Two-way bound to `.searchable`.
    var query: String = ""

    private(set) var repos: [Repository] = []
    private(set) var status: Status = .idle
    /// The trimmed query backing the current results — used for the empty-state label.
    private(set) var searchedQuery: String = ""
    /// Recent searches, most-recent first (persisted via `history`).
    private(set) var recent: [RecentSearch] = []
    /// True once `loadHistory()` has run, so the idle view doesn't flash the empty prompt before
    /// persisted history is read.
    private(set) var didLoadHistory = false

    /// Bumped by `retry()`/`selectRecent(_:)` and folded into the View's `.task` id so they re-run
    /// through the same structured-cancellation channel instead of an orphaned `Task`.
    private(set) var retryToken: Int = 0

    private let client: GitHubAPIClient
    private let history: SearchHistoryStore
    private let debounce: Duration
    private let perPage: Int

    /// Identity of the in-flight search; guards a superseded task from overwriting newer state.
    private var generation = 0
    /// Last trimmed query actually searched, to skip no-op re-searches (e.g. a trailing-space edit).
    private var lastSearched: String?
    /// Distinguishes an explicit retry from a keystroke, so a retry can skip the debounce.
    private var handledRetryToken = 0

    init(client: GitHubAPIClient,
         history: SearchHistoryStore = InMemorySearchHistoryStore(),
         debounce: Duration = .milliseconds(350),
         perPage: Int = 30) {
        self.client = client
        self.history = history
        self.debounce = debounce
        self.perPage = perPage
    }

    /// Called from the View's `.task(id:)`. Runs the debounce + search INLINE (no inner unstructured
    /// `Task`) so SwiftUI cancels it when the query changes or the view disappears — which tears down
    /// the in-flight URLSession request.
    func queryChanged() async {
        let isRetry = retryToken != handledRetryToken
        handledRetryToken = retryToken
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            reset()
            return
        }
        if isRetry {
            await search(trimmed) // explicit retry: run immediately, still within `.task(id:)`
            return
        }
        guard trimmed != lastSearched else { return } // ignore no-op edits (e.g. a trailing space)
        if case .error = status { status = .idle }     // don't strand a stale error while typing a new query
        do {
            try await Task.sleep(for: debounce)
        } catch {
            return // superseded by a newer query, or the view disappeared
        }
        await search(trimmed)
    }

    /// Re-runs the current query through `.task(id:)`.
    func retry() {
        retryToken &+= 1
    }

    /// Loads persisted recent searches (call on appear).
    func loadHistory() async {
        recent = await history.recent()
        didLoadHistory = true
    }

    /// Runs a tapped recent search immediately (bypasses the debounce, like a retry).
    func selectRecent(_ query: String) {
        self.query = query
        retryToken &+= 1
    }

    func clearHistory() async {
        recent = [] // update UI immediately; avoids races between out-of-order read-backs
        await history.clear()
    }

    func removeRecent(_ query: String) async {
        recent.removeAll { $0.query == query } // update UI immediately (no read-back race)
        await history.remove(query)
    }

    private func reset() {
        generation += 1 // invalidate any in-flight search
        repos = []
        status = .idle
        lastSearched = nil
        searchedQuery = ""
    }

    private func search(_ query: String) async {
        generation += 1
        let token = generation
        lastSearched = query
        searchedQuery = query
        status = .loading
        do {
            let response = try await client.searchRepositories(query: query, page: 1, perPage: perPage)
            guard token == generation else { return } // a newer search superseded this one
            repos = response.items
            status = response.items.isEmpty ? .empty : .loaded
            await recordHistory(query, token: token)
        } catch is CancellationError {
            guard token == generation else { return } // superseded → let the newer search settle state
            // Torn down (e.g. view disappeared) with no newer search: derive a stable status, never strand `.loading`.
            status = repos.isEmpty ? .idle : .loaded
        } catch {
            guard token == generation else { return }
            status = .error(Self.message(for: error))
        }
    }

    private func recordHistory(_ query: String, token: Int) async {
        guard !Task.isCancelled else { return }   // search abandoned (e.g. the view was torn down)
        await history.record(query)
        guard token == generation else { return } // superseded — let the newer search publish `recent`
        recent = await history.recent()
    }

    private static func message(for error: any Error) -> String {
        guard let apiError = error as? GitHubAPIError else {
            return "Something went wrong. Please check your connection and try again."
        }
        switch apiError {
        case .rateLimited:
            return "GitHub’s rate limit was reached. Please wait a moment and try again."
        case .invalidQuery:
            return "That search couldn’t be understood. Try different keywords."
        case .server:
            return "GitHub is having trouble right now. Please try again shortly."
        case .decoding:
            return "Received an unexpected response from GitHub."
        case .transport:
            return "Couldn’t reach GitHub. Please check your connection and try again."
        case .http, .invalidURL:
            return "Something went wrong. Please try again."
        }
    }
}
