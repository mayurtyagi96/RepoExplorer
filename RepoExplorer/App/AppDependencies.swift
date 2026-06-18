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

    /// Resolves the graph for the running process, substituting canned data for UI tests
    /// (launch argument `-uiTestStubResults`) so flows can be exercised without the network.
    static func current() -> AppDependencies {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestStubResults") {
            return AppDependencies(apiClient: PreviewGitHubAPIClient(response: .sampleResponse))
        }
        #endif
        return .live
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(client: apiClient)
    }
}
