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
            Label {
                Text("Couldn’t load results")
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.issues)
            }
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}

#if DEBUG
#Preview {
    ErrorStateView(message: "GitHub’s rate limit was reached. Please wait a moment and try again.") {}
}
#endif
