//
//  RecentSearch.swift
//  RepoExplorer
//
//  A previously-run search query and when it was last run. Persisted to disk.
//

import Foundation

/// `nonisolated` so its `Codable` conformance can be used from the off-main history-store actor.
nonisolated struct RecentSearch: Codable, Sendable, Identifiable, Hashable {
    var id: String { query }
    let query: String
    let date: Date
}
