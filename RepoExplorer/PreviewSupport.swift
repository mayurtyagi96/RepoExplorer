//
//  PreviewSupport.swift
//  RepoExplorer
//
//  DEBUG-only sample data and a canned API client for SwiftUI previews.
//

#if DEBUG
import Foundation

/// Returns a fixed response without touching the network. Used by previews.
nonisolated struct PreviewGitHubAPIClient: GitHubAPIClient {
    let response: SearchResponse

    nonisolated func searchRepositories(query: String, page: Int, perPage: Int) async throws -> SearchResponse {
        response
    }
}

extension Owner {
    static func make(
        login: String = "apple",
        avatarURL: String = "https://avatars.githubusercontent.com/u/10639145?v=4",
        htmlURL: String = "https://github.com/apple"
    ) -> Owner {
        Owner(login: login, avatarURL: avatarURL, htmlURL: htmlURL)
    }
}

extension License {
    static func make(
        key: String = "apache-2.0",
        name: String = "Apache License 2.0",
        spdxID: String? = "Apache-2.0"
    ) -> License {
        License(key: key, name: name, spdxID: spdxID)
    }
}

extension Repository {
    static func make(
        id: Int = 1,
        name: String = "swift",
        fullName: String = "apple/swift",
        owner: Owner? = .make(),
        description: String? = "The Swift Programming Language",
        htmlURL: String = "https://github.com/apple/swift",
        stargazersCount: Int = 67_000,
        forksCount: Int = 10_300,
        watchersCount: Int = 67_000,
        openIssuesCount: Int = 8_100,
        language: String? = "C++",
        topics: [String]? = ["swift", "compiler", "language"],
        license: License? = .make(),
        updatedAt: String = "2026-06-18T00:00:00Z"
    ) -> Repository {
        Repository(
            id: id, name: name, fullName: fullName, owner: owner, description: description,
            htmlURL: htmlURL, stargazersCount: stargazersCount, forksCount: forksCount,
            watchersCount: watchersCount, openIssuesCount: openIssuesCount, language: language,
            topics: topics, license: license, updatedAt: updatedAt
        )
    }

    static let samples: [Repository] = [
        .make(),
        .make(id: 2, name: "alamofire", fullName: "Alamofire/Alamofire",
              owner: .make(login: "Alamofire"),
              description: "Elegant HTTP Networking in Swift",
              stargazersCount: 41_000, forksCount: 7_600, language: "Swift",
              topics: ["http", "networking"]),
        .make(id: 3, name: "swift-composable-architecture",
              fullName: "pointfreeco/swift-composable-architecture",
              owner: .make(login: "pointfreeco"),
              description: "A library for building applications in a consistent and understandable way.",
              stargazersCount: 13_000, forksCount: 1_400, language: "Swift",
              topics: ["architecture", "swiftui"]),
    ]
}

extension SearchResponse {
    static let sampleResponse = SearchResponse(
        totalCount: Repository.samples.count,
        incompleteResults: false,
        items: Repository.samples
    )
}

extension SearchViewModel {
    /// A view model wired to canned data, for previews. Zero debounce so the preview's `.task`
    /// resolves immediately.
    static func previewLoaded() -> SearchViewModel {
        let viewModel = SearchViewModel(client: PreviewGitHubAPIClient(response: .sampleResponse),
                                        debounce: .zero)
        viewModel.query = "swift"
        return viewModel
    }
}
#endif
