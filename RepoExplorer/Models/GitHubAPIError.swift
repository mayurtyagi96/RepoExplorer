//
//  GitHubAPIError.swift
//  RepoExplorer
//
//  Errors thrown by the networking layer, plus the decoded GitHub error body.
//

import Foundation

/// The JSON error body GitHub returns on failures (e.g. 403 rate limit, 422 validation).
nonisolated struct GitHubErrorBody: Decodable, Sendable {
    let message: String
    let documentationURL: String?

    enum CodingKeys: String, CodingKey {
        case message
        case documentationURL = "documentation_url"
    }
}

/// Errors surfaced by `GitHubAPIClient`. `Sendable` + `nonisolated` so they can be thrown
/// from the off-main client and caught by the `@MainActor` view model.
nonisolated enum GitHubAPIError: Error, Sendable, Equatable {
    /// Could not construct a valid request URL.
    case invalidURL
    /// 403/429 — primary or secondary rate limit. `retryAfter` derived from headers when available.
    case rateLimited(retryAfter: TimeInterval?)
    /// 422 — GitHub could not parse the search query.
    case invalidQuery(message: String?)
    /// 5xx — transient server-side failure.
    case server(status: Int)
    /// Other non-success HTTP status.
    case http(status: Int, message: String?)
    /// Response body could not be decoded.
    case decoding
    /// Network/transport failure (not a cancellation).
    case transport
}
