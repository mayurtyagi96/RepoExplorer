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
    let historyStore: SearchHistoryStore

    static let live = AppDependencies(
        apiClient: LiveGitHubAPIClient(),
        historyStore: UserDefaultsSearchHistoryStore()
    )

    /// Resolves the graph for the running process, substituting canned data for UI tests
    /// (`-uiTestStubResults`) on an isolated, freshly-cleared UserDefaults suite. With
    /// `-uiTestSeedHistory`, pre-populates recent searches so the idle screen has content.
    static func current() -> AppDependencies {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestStubResults") {
            let suiteName = "com.mayur.RepoExplorer.uitests"
            let defaults = UserDefaults(suiteName: suiteName)
            defaults?.removePersistentDomain(forName: suiteName)
            if ProcessInfo.processInfo.arguments.contains("-uiTestSeedHistory") {
                let seeded = ["swift", "alamofire"].map { RecentSearch(query: $0, date: Date()) }
                if let data = try? JSONEncoder().encode(seeded) {
                    defaults?.set(data, forKey: UserDefaultsSearchHistoryStore.defaultKey)
                }
            }
            return AppDependencies(
                apiClient: PreviewGitHubAPIClient(response: .sampleResponse),
                historyStore: UserDefaultsSearchHistoryStore(suiteName: suiteName)
            )
        }
        #endif
        return .live
    }

    func makeSearchViewModel() -> SearchViewModel {
        let viewModel = SearchViewModel(client: apiClient, history: historyStore)
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-uiTestQuery"), i + 1 < args.count {
            viewModel.query = args[i + 1] // pre-fill the search (drives a deterministic results screen)
        }
        #endif
        return viewModel
    }
}
