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
                .navigationDestination(for: Repository.self) { repo in
                    RepositoryDetailView(repo: repo)
                }
        }
        .tint(Theme.accent)
        .searchable(text: $viewModel.query, prompt: "Search topics, libraries, repos")
        // `.task(id:)` re-runs on every query change (cancelling the prior run) and on disappear,
        // which is what tears down the in-flight request. `retryToken` re-runs the same query.
        .task(id: taskID) {
            await viewModel.queryChanged()
        }
        .task {
            await viewModel.loadHistory()
        }
    }

    private var taskID: String { "\(viewModel.query)#\(viewModel.retryToken)" }

    @ViewBuilder
    private var content: some View {
        Group {
            switch viewModel.status {
            case .idle:
                idleContent
            case .loading:
                LoadingListView()
                    .transition(.opacity)
            case .empty:
                ContentUnavailableView.search(text: viewModel.searchedQuery)
                    .transition(.opacity)
            case .error(let message):
                ErrorStateView(message: message, retry: viewModel.retry)
                    .transition(.opacity)
            case .loaded:
                resultsList
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: viewModel.status)
    }

    @ViewBuilder
    private var idleContent: some View {
        if !viewModel.recent.isEmpty {
            recentSearches.transition(.opacity)
        } else if viewModel.didLoadHistory {
            ContentUnavailableView {
                Label {
                    Text("Discover repositories")
                } icon: {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.accentGradient)
                }
            } description: {
                Text("Search GitHub for a topic or library to get started.")
            }
            .transition(.opacity)
        } else {
            Color.clear // brief, until persisted history loads — avoids flashing the prompt
        }
    }

    private var resultsList: some View {
        List(viewModel.repos) { repo in
            NavigationLink(value: repo) {
                RepositoryRow(repo: repo)
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        }
        .listStyle(.plain)
        .animation(.snappy, value: viewModel.repos)
    }

    private var recentSearches: some View {
        List {
            Section {
                ForEach(viewModel.recent) { item in
                    Button {
                        viewModel.selectRecent(item.query)
                    } label: {
                        Label(item.query, systemImage: "clock.arrow.circlepath")
                            .foregroundStyle(.primary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await viewModel.removeRecent(item.query) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Recent searches")
                    Spacer()
                    Button("Clear") {
                        Task { await viewModel.clearHistory() }
                    }
                    .font(.caption.weight(.semibold))
                    .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
    }
}

#if DEBUG
#Preview("Results") {
    SearchView(viewModel: .previewLoaded())
}
#endif
