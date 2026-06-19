//
//  RepositoryRow.swift
//  RepoExplorer
//
//  A single repository result, rendered as an elevated card.
//

import SwiftUI

struct RepositoryRow: View {
    let repo: Repository

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                AvatarView(url: repo.owner?.avatarImageURL, size: 40)

                VStack(alignment: .leading, spacing: 1) {
                    Text(repo.fullName)
                        .font(.headline)
                        .lineLimit(1)
                    if let owner = repo.owner {
                        Text("@\(owner.login)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let description = repo.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: Theme.Spacing.s) {
                statChip(systemImage: "star.fill", text: repo.stargazersCount.formattedCompact, color: Theme.stars)
                if let language = repo.language, !language.isEmpty {
                    languageChip(language)
                }
                statChip(systemImage: "tuningfork", text: repo.forksCount.formattedCompact, color: Theme.forks)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .repoCard()
    }

    private func statChip(systemImage: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage).foregroundStyle(color)
            Text(text).foregroundStyle(.primary)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }

    private func languageChip(_ language: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(Theme.accent).frame(width: 8, height: 8)
            Text(language).foregroundStyle(.primary)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.accent.opacity(0.12), in: Capsule())
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack {
            RepositoryRow(repo: .make())
            RepositoryRow(repo: .make(id: 2, name: "alamofire", fullName: "Alamofire/Alamofire",
                                      description: "Elegant HTTP Networking in Swift", language: "Swift"))
        }
        .padding()
    }
}
#endif
