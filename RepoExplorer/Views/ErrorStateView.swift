//
//  ErrorStateView.swift
//  RepoExplorer
//
//  Full-screen error state with a retry action.
//

import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn’t load results", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

#if DEBUG
#Preview {
    ErrorStateView(message: "GitHub’s rate limit was reached. Please wait a moment and try again.") {}
}
#endif
