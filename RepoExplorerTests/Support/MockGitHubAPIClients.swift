//
//  MockGitHubAPIClients.swift
//  RepoExplorerTests
//

import Foundation
@testable import RepoExplorer

/// Stateless stub returning a canned success or failure.
struct StubGitHubAPIClient: GitHubAPIClient {
    var response: SearchResponse = SearchResponse(totalCount: 0, incompleteResults: false, items: [])
    var failure: (any Error & Sendable)?

    init(response: SearchResponse) { self.response = response }
    init(failure: any Error & Sendable) { self.failure = failure }

    nonisolated func searchRepositories(query: String, page: Int, perPage: Int) async throws -> SearchResponse {
        if let failure { throw failure }
        return response
    }
}

/// Records the queries it received and can simulate a slow response (sleeping FIRST so that
/// task cancellation is observed before any recording).
actor SpyGitHubAPIClient: GitHubAPIClient {
    private(set) var receivedQueries: [String] = []
    private let response: SearchResponse
    private let failure: (any Error & Sendable)?
    private let delay: Duration

    init(response: SearchResponse = SearchResponse(totalCount: 0, incompleteResults: false, items: []),
         failure: (any Error & Sendable)? = nil,
         delay: Duration = .zero) {
        self.response = response
        self.failure = failure
        self.delay = delay
    }

    func searchRepositories(query: String, page: Int, perPage: Int) async throws -> SearchResponse {
        if delay != .zero {
            try await Task.sleep(for: delay)
        }
        receivedQueries.append(query)
        if let failure { throw failure }
        return response
    }
}

/// Ignores cancellation: its sleep is swallowed, so it returns its response even when the task is
/// cancelled — exercises the "client returns normally on a cancelled request" path.
actor CancellationIgnoringClient: GitHubAPIClient {
    private let response: SearchResponse
    private let delay: Duration

    init(response: SearchResponse, delay: Duration = .milliseconds(200)) {
        self.response = response
        self.delay = delay
    }

    func searchRepositories(query: String, page: Int, perPage: Int) async throws -> SearchResponse {
        try? await Task.sleep(for: delay) // swallow cancellation; return normally
        return response
    }
}

/// Returns queued results in order; the last result repeats once the queue is exhausted.
/// Useful for testing transitions like fail-then-succeed (retry recovery).
actor SequencedGitHubAPIClient: GitHubAPIClient {
    private var results: [Result<SearchResponse, any Error & Sendable>]
    private(set) var callCount = 0

    init(_ results: [Result<SearchResponse, any Error & Sendable>]) {
        precondition(!results.isEmpty, "SequencedGitHubAPIClient needs at least one result")
        self.results = results
    }

    func searchRepositories(query: String, page: Int, perPage: Int) async throws -> SearchResponse {
        callCount += 1
        let result = results.count > 1 ? results.removeFirst() : results[0]
        return try result.get()
    }
}
