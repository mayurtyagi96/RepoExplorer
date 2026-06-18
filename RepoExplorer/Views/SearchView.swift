//
//  SearchView.swift
//  RepoExplorer
//
//  Root search screen: a searchable list of repositories with idle/loading/empty/error states.
//

import SwiftUI

struct SearchView: View {
    // The App owns the view model (its `@State`); the View only binds to it.
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("RepoExplorer")
        }
        .searchable(text: $viewModel.query, prompt: "Search topics, libraries, repos")
        // `.task(id:)` re-runs on every query change (cancelling the prior run) and on disappear,
        // which is what tears down the in-flight request. `retryToken` re-runs the same query.
        .task(id: taskID) {
            await viewModel.queryChanged()
        }
    }

    private var taskID: String { "\(viewModel.query)#\(viewModel.retryToken)" }

    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .idle:
            ContentUnavailableView(
                "Discover repositories",
                systemImage: "magnifyingglass",
                description: Text("Search GitHub for a topic or library to get started.")
            )
        case .loading:
            ProgressView("Searching…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            ContentUnavailableView.search(text: viewModel.searchedQuery)
        case .error(let message):
            ErrorStateView(message: message, retry: viewModel.retry)
        case .loaded:
            resultsList
        }
    }

    private var resultsList: some View {
        List(viewModel.repos) { repo in
            RepositoryRow(repo: repo)
        }
        .listStyle(.plain)
    }
}

#if DEBUG
#Preview("Results") {
    SearchView(viewModel: .previewLoaded())
}
#endif
