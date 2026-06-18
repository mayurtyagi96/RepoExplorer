//
//  SearchHistoryStoreTests.swift
//  RepoExplorerTests
//

import XCTest
@testable import RepoExplorer

@MainActor
final class SearchHistoryStoreTests: XCTestCase {
    private let suite = "test.repoexplorer.history"

    // async to satisfy the project rule: a synchronous @MainActor XCTest lifecycle method can be
    // invoked off-main and trap.
    override func setUp() async throws {
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
    }

    override func tearDown() async throws {
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
    }

    private func makeStore(maxCount: Int = 20) -> UserDefaultsSearchHistoryStore {
        UserDefaultsSearchHistoryStore(suiteName: suite, maxCount: maxCount)
    }

    func test_record_keepsMostRecentFirst() async {
        let store = makeStore()
        await store.record("swift")
        await store.record("alamofire")
        let recent = await store.recent()
        XCTAssertEqual(recent.map(\.query), ["alamofire", "swift"])
    }

    func test_record_dedupesCaseInsensitively_andMovesToFront() async {
        let store = makeStore()
        await store.record("swift")
        await store.record("alamofire")
        await store.record("Swift")   // duplicate of "swift"
        let recent = await store.recent()
        XCTAssertEqual(recent.map(\.query), ["Swift", "alamofire"])
    }

    func test_record_capsAtMaxCount() async {
        let store = makeStore(maxCount: 3)
        for query in ["a", "b", "c", "d", "e"] { await store.record(query) }
        let recent = await store.recent()
        XCTAssertEqual(recent.map(\.query), ["e", "d", "c"])
    }

    func test_record_ignoresBlankQuery() async {
        let store = makeStore()
        await store.record("   ")
        let recent = await store.recent()
        XCTAssertTrue(recent.isEmpty)
    }

    func test_remove() async {
        let store = makeStore()
        await store.record("swift")
        await store.record("alamofire")
        await store.remove("swift")
        let recent = await store.recent()
        XCTAssertEqual(recent.map(\.query), ["alamofire"])
    }

    func test_clear() async {
        let store = makeStore()
        await store.record("swift")
        await store.clear()
        let recent = await store.recent()
        XCTAssertTrue(recent.isEmpty)
    }

    /// A fresh instance on the same suite reads what a prior instance wrote — i.e. it survives relaunch.
    func test_persistsAcrossInstances() async {
        let first = makeStore()
        await first.record("swift")

        let second = makeStore()
        let recent = await second.recent()
        XCTAssertEqual(recent.map(\.query), ["swift"])
    }
}
