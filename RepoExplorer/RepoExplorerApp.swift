//
//  RepoExplorerApp.swift
//  RepoExplorer
//
//  Created by Mayur on 18/06/26.
//

import SwiftUI

@main
struct RepoExplorerApp: App {
    @State private var searchViewModel = AppDependencies.live.makeSearchViewModel()

    var body: some Scene {
        WindowGroup {
            SearchView(viewModel: searchViewModel)
        }
    }
}
