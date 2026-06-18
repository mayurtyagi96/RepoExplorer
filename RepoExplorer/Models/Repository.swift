//
//  Repository.swift
//  RepoExplorer
//
//  A GitHub repository and its nested owner/license, as returned by the
//  /search/repositories endpoint.
//

import Foundation

// Models are `nonisolated` so their `Decodable` conformances can be used from the
// off-main networking layer. Under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, a
// plain (implicitly main-isolated) `Decodable` conformance cannot be decoded from a
// `nonisolated`/`@concurrent` context (#IsolatedConformances).

nonisolated struct Repository: Decodable, Sendable, Identifiable, Hashable {
    let id: Int
    let name: String
    let fullName: String
    let owner: Owner?
    let description: String?
    let htmlURL: String
    let stargazersCount: Int
    let forksCount: Int
    let watchersCount: Int
    let openIssuesCount: Int
    let language: String?
    /// `topics` may be entirely absent on some objects; use `topicList` for a non-optional view.
    let topics: [String]?
    let license: License?
    let updatedAt: String

    /// Topics with absent/null coalesced to an empty array.
    var topicList: [String] { topics ?? [] }

    /// Parsed repository web URL, if the string is a valid URL.
    var webURL: URL? { URL(string: htmlURL) }

    // Explicit snake_case keys. We deliberately do NOT use `.convertFromSnakeCase`, which maps
    // `html_url` -> `htmlUrl` (lowercase "rl") and would make `htmlURL`/`spdxID` fail to decode.
    enum CodingKeys: String, CodingKey {
        case id, name, owner, description, language, license, topics
        case fullName = "full_name"
        case htmlURL = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case watchersCount = "watchers_count"
        case openIssuesCount = "open_issues_count"
        case updatedAt = "updated_at"
    }
}

nonisolated struct Owner: Decodable, Sendable, Hashable {
    let login: String
    let avatarURL: String
    let htmlURL: String

    var avatarImageURL: URL? { URL(string: avatarURL) }
    var profileURL: URL? { URL(string: htmlURL) }

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
    }
}

nonisolated struct License: Decodable, Sendable, Hashable {
    let key: String
    let name: String
    let spdxID: String?

    /// Short label preferring the SPDX id, falling back to the full name.
    /// GitHub may return "NOASSERTION" or an empty/`nil` SPDX id.
    var shortName: String {
        if let spdxID, !spdxID.isEmpty, spdxID != "NOASSERTION" { return spdxID }
        return name
    }

    enum CodingKeys: String, CodingKey {
        case key, name
        case spdxID = "spdx_id"
    }
}
