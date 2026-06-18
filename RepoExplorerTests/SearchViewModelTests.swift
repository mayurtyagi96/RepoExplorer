//
//  SearchViewModelTests.swift
//  RepoExplorerTests
//

import XCTest
@testable import RepoExplorer

@MainActor
final class SearchViewModelTests: XCTestCase {

    private func response(_ repos: [Repository], total: Int? = nil) -> SearchResponse {
        SearchResponse(totalCount: total ?? repos.count, incompleteResults: false, items: repos)
    }

    func test_search_success_setsLoaded() async {
        let viewModel = SearchViewModel(client: StubGitHubAPIClient(response: response([.make()])),
                                        debounce: .zero)
        viewModel.query = "swift"

        await viewModel.queryChanged()

        XCTAssertEqual(viewModel.status, .loaded)
        XCTAssertEqual(viewModel.repos.count, 1)
    }

    func test_search_emptyResults_setsEmpty() async {
        let viewModel = SearchViewModel(client: StubGitHubAPIClient(response: response([])),
                                        debounce: .zero)
        viewModel.query = "zzzznotathing"

        await viewModel.queryChanged()

        XCTAssertEqual(viewModel.status, .empty)
        XCTAssertTrue(viewModel.repos.isEmpty)
    }

    func test_search_failure_setsError() async {
        let viewModel = SearchViewModel(
            client: StubGitHubAPIClient(failure: GitHubAPIError.rateLimited(retryAfter: nil)),
            debounce: .zero
        )
        viewModel.query = "swift"

        await viewModel.queryChanged()

        guard case .error = viewModel.status else {
            return XCTFail("expected .error, got \(viewModel.status)")
        }
    }

    func test_blankQuery_resetsToIdle() async {
        let viewModel = SearchViewModel(client: StubGitHubAPIClient(response: response([.make()])),
                                        debounce: .zero)
        viewModel.query = "   "

        await viewModel.queryChanged()

        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertTrue(viewModel.repos.isEmpty)
    }

    /// Two rapid query changes: the first is cancelled (as SwiftUI's `.task(id:)` would) before its
    /// debounce elapses, so only the latest query reaches the network.
    func test_debounce_coalescesRapidQueries() async {
        let spy = SpyGitHubAPIClient(response: response([.make()]))
        let viewModel = SearchViewModel(client: spy, debounce: .milliseconds(120))

        viewModel.query = "a"
        let first = Task { await viewModel.queryChanged() }
        try? await Task.sleep(for: .milliseconds(30))   // let "a" enter its debounce sleep
        first.cancel()
        viewModel.query = "ab"
        let second = Task { await viewModel.queryChanged() }

        _ = await first.value
        _ = await second.value

        let queries = await spy.receivedQueries
        XCTAssertEqual(queries, ["ab"])
    }

    /// Cancelling an in-flight search (e.g. leaving the screen) must not strand the spinner.
    func test_cancellation_doesNotStrandLoading() async {
        let spy = SpyGitHubAPIClient(response: response([.make()]), delay: .milliseconds(300))
        let viewModel = SearchViewModel(client: spy, debounce: .zero)
        viewModel.query = "swift"

        let task = Task { await viewModel.queryChanged() }
        try? await Task.sleep(for: .milliseconds(60))   // reach the in-flight network await
        task.cancel()
        await task.value

        XCTAssertNotEqual(viewModel.status, .loading)
    }

    func test_retry_bumpsRetryToken() async {
        let viewModel = SearchViewModel(client: StubGitHubAPIClient(response: response([])))
        XCTAssertEqual(viewModel.retryToken, 0)
        viewModel.retry()
        XCTAssertEqual(viewModel.retryToken, 1)
    }

    /// error -> Retry -> success must recover to .loaded (covers the retry-recovery path end to end).
    func test_retry_afterError_recoversToLoaded() async {
        let client = SequencedGitHubAPIClient([
            .failure(GitHubAPIError.server(status: 500)),
            .success(response([.make()])),
        ])
        let viewModel = SearchViewModel(client: client, debounce: .zero)
        viewModel.query = "swift"

        await viewModel.queryChanged()
        guard case .error = viewModel.status else {
            return XCTFail("expected .error, got \(viewModel.status)")
        }

        viewModel.retry()
        await viewModel.queryChanged()

        XCTAssertEqual(viewModel.status, .loaded)
        XCTAssertEqual(viewModel.repos.count, 1)
    }

    /// A whitespace-only edit that trims to the same query must not trigger a second fetch.
    func test_trailingSpaceEdit_doesNotRefetch() async {
        let spy = SpyGitHubAPIClient(response: response([.make()]))
        let viewModel = SearchViewModel(client: spy, debounce: .zero)

        viewModel.query = "swift"
        await viewModel.queryChanged()
        viewModel.query = "swift "   // trims back to "swift"
        await viewModel.queryChanged()

        let queries = await spy.receivedQueries
        XCTAssertEqual(queries, ["swift"])
    }

    /// A superseded search's late completion must not overwrite the newer search's state.
    func test_supersededSearch_doesNotOverwriteNewerStatus() async {
        let spy = SpyGitHubAPIClient(response: response([.make()]), delay: .milliseconds(150))
        let viewModel = SearchViewModel(client: spy, debounce: .zero)

        viewModel.query = "a"
        let taskA = Task { await viewModel.queryChanged() }
        try? await Task.sleep(for: .milliseconds(40))   // A is in flight (generation 1, .loading)

        viewModel.query = "ab"
        let taskB = Task { await viewModel.queryChanged() }
        try? await Task.sleep(for: .milliseconds(40))   // B has set generation 2 + .loading
        taskA.cancel()                                  // A's late completion must be a no-op

        _ = await taskA.value
        XCTAssertEqual(viewModel.status, .loading)      // B still loading; A did not strand/reset it

        _ = await taskB.value
        XCTAssertEqual(viewModel.status, .loaded)       // B settles the state
    }

    // MARK: - Search history (Phase 3)

    func test_successfulSearch_recordsHistory() async {
        let store = InMemorySearchHistoryStore()
        let viewModel = SearchViewModel(client: StubGitHubAPIClient(response: response([.make()])),
                                        history: store, debounce: .zero)
        viewModel.query = "swift"

        await viewModel.queryChanged()

        let recorded = await store.recent()
        XCTAssertEqual(recorded.map(\.query), ["swift"])
        XCTAssertEqual(viewModel.recent.map(\.query), ["swift"])
    }

    func test_cancelledSearch_doesNotRecordHistory() async {
        let store = InMemorySearchHistoryStore()
        let spy = SpyGitHubAPIClient(response: response([.make()]), delay: .milliseconds(200))
        let viewModel = SearchViewModel(client: spy, history: store, debounce: .zero)
        viewModel.query = "swift"

        let task = Task { await viewModel.queryChanged() }
        try? await Task.sleep(for: .milliseconds(60))
        task.cancel()
        await task.value

        let recorded = await store.recent()
        XCTAssertTrue(recorded.isEmpty)
    }

    /// Even when the client returns a value despite cancellation (it doesn't throw), an abandoned
    /// search must not record history — the success branch must guard on cancellation.
    func test_cancelledSearch_doesNotRecordHistory_whenClientReturnsNormally() async {
        let store = InMemorySearchHistoryStore()
        let client = CancellationIgnoringClient(response: response([.make()]))
        let viewModel = SearchViewModel(client: client, history: store, debounce: .zero)
        viewModel.query = "swift"

        let task = Task { await viewModel.queryChanged() }
        try? await Task.sleep(for: .milliseconds(60))
        task.cancel()
        await task.value

        let recorded = await store.recent()
        XCTAssertTrue(recorded.isEmpty)
    }

    func test_loadHistory_populatesRecent() async {
        let store = InMemorySearchHistoryStore()
        await store.record("swift")
        let viewModel = SearchViewModel(client: StubGitHubAPIClient(response: response([])), history: store)

        await viewModel.loadHistory()

        XCTAssertEqual(viewModel.recent.map(\.query), ["swift"])
    }

    func test_selectRecent_rerunsSearchImmediately() async {
        let spy = SpyGitHubAPIClient(response: response([.make()]))
        let viewModel = SearchViewModel(client: spy, history: InMemorySearchHistoryStore(),
                                        debounce: .milliseconds(500))

        viewModel.selectRecent("swift")
        await viewModel.queryChanged()   // mirrors the View's `.task(id:)` firing

        XCTAssertEqual(viewModel.query, "swift")
        let queries = await spy.receivedQueries
        XCTAssertEqual(queries, ["swift"])
        XCTAssertEqual(viewModel.status, .loaded)
    }

    func test_clearHistory_emptiesRecent() async {
        let store = InMemorySearchHistoryStore()
        await store.record("swift")
        let viewModel = SearchViewModel(client: StubGitHubAPIClient(response: response([])), history: store)
        await viewModel.loadHistory()

        await viewModel.clearHistory()

        XCTAssertTrue(viewModel.recent.isEmpty)
        let stored = await store.recent()
        XCTAssertTrue(stored.isEmpty)
    }
}
