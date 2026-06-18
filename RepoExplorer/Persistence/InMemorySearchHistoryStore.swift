//
//  InMemorySearchHistoryStore.swift
//  RepoExplorer
//
//  Non-persistent SearchHistoryStore — the default for previews and tests.
//

import Foundation

actor InMemorySearchHistoryStore: SearchHistoryStore {
    private var entries: [RecentSearch] = []
    private let maxCount = 20

    func recent() -> [RecentSearch] { entries }
    func record(_ query: String) { entries = recentSearches(byInserting: query, into: entries, maxCount: maxCount, now: Date()) }
    func remove(_ query: String) { entries.removeAll { $0.query.caseInsensitiveCompare(query) == .orderedSame } }
    func clear() { entries = [] }
}
