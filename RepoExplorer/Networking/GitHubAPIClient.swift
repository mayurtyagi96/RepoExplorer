//
//  GitHubAPIClient.swift
//  RepoExplorer
//
//  Abstraction over the GitHub repository-search endpoint.
//

import Foundation

/// Searches GitHub repositories. `Sendable` so a `@MainActor` view model can hold and call it
/// across isolation domains. The requirement is `nonisolated` so conforming types are NOT pulled
/// onto the main actor — otherwise (under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`) the witness
/// would be inferred `@MainActor` and JSON decoding would run on the main thread.
protocol GitHubAPIClient: Sendable {
    nonisolated func searchRepositories(query: String, page: Int, perPage: Int) async throws -> SearchResponse
}
