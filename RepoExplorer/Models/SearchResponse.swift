//
//  SearchResponse.swift
//  RepoExplorer
//
//  Top-level envelope returned by GET /search/repositories.
//

import Foundation

nonisolated struct SearchResponse: Decodable, Sendable {
    /// Total matches reported by GitHub (can exceed the 1000 results actually reachable via paging).
    let totalCount: Int
    /// `true` when GitHub timed out and returned a partial result set.
    let incompleteResults: Bool
    let items: [Repository]

    enum CodingKeys: String, CodingKey {
        case items
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
    }
}
