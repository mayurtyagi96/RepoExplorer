//
//  AppDependencies.swift
//  RepoExplorer
//
//  Composition root: constructs the live services the app graph depends on and
//  builds view models from them. Swap `apiClient` for a mock to drive previews.
//

import Foundation

@MainActor
struct AppDependencies {
    let apiClient: GitHubAPIClient
    let historyStore: SearchHistoryStore

    static let live = AppDependencies(
        apiClient: LiveGitHubAPIClient(),
        historyStore: UserDefaultsSearchHistoryStore()
    )

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(client: apiClient, history: historyStore)
    }
}
