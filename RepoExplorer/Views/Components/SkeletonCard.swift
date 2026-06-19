//
//  SkeletonCard.swift
//  RepoExplorer
//
//  Placeholder cards shown while a search is loading.
//

import SwiftUI

struct SkeletonCard: View {
    private let bar = Color.primary.opacity(0.12)

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                RoundedRectangle(cornerRadius: 9, style: .continuous).fill(bar).frame(width: 40, height: 40)
                RoundedRectangle(cornerRadius: 5, style: .continuous).fill(bar).frame(width: 150, height: 14)
            }
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(bar).frame(height: 11)
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(bar).frame(width: 200, height: 11)
            HStack(spacing: Theme.Spacing.s) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().fill(bar).frame(width: 52, height: 18)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .repoCard()
    }
}

/// A shimmering column of skeleton cards — the loading state for search.
struct LoadingListView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonCard()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                }
            }
        }
        .scrollDisabled(true)
        .shimmering()
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    LoadingListView()
}
#endif
