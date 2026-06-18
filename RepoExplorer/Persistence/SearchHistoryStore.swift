//
//  SearchHistoryStore.swift
//  RepoExplorer
//
//  Persistence boundary for the user's recent searches.
//

import Foundation

/// Persists recent search queries. `Sendable` so the `@MainActor` view model can hold and `await`
/// it; requirements are `nonisolated` so conformers (actors) stay off the main actor.
protocol SearchHistoryStore: Sendable {
    nonisolated func recent() async -> [RecentSearch]
    nonisolated func record(_ query: String) async
    nonisolated func remove(_ query: String) async
    nonisolated func clear() async
}

/// Most-recently-used insertion shared by every store: trims, drops any case-insensitive duplicate,
/// prepends the query, and caps the list. Pure — no isolation required.
nonisolated func recentSearches(byInserting query: String,
                                into entries: [RecentSearch],
                                maxCount: Int,
                                now: Date) -> [RecentSearch] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return entries }
    var result = entries.filter { $0.query.caseInsensitiveCompare(trimmed) != .orderedSame }
    result.insert(RecentSearch(query: trimmed, date: now), at: 0)
    return Array(result.prefix(maxCount))
}
