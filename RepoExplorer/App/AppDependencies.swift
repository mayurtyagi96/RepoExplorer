//
//  AppDependencies.swift
//  RepoExplorer
//
//  Composition root: constructs the live services the app graph depends on and
//  builds view models from them. Swap `apiClient` for a mock to drive tests/previews.
//

import Foundation

@MainActor
struct AppDependencies {
    let apiClient: GitHubAPIClient

    static let live = AppDependencies(apiClient: LiveGitHubAPIClient())

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(client: apiClient)
    }
}
