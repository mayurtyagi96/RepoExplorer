//
//  RepositoryRow.swift
//  RepoExplorer
//
//  A single repository result row.
//

import SwiftUI

struct RepositoryRow: View {
    let repo: Repository

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                AvatarView(url: repo.owner?.avatarImageURL, size: 22)

                Text(repo.fullName)
                    .font(.headline)
                    .lineLimit(1)
            }

            if let description = repo.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 14) {
                Label(repo.stargazersCount.formattedCompact, systemImage: "star.fill")
                if let language = repo.language, !language.isEmpty {
                    Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Label(repo.forksCount.formattedCompact, systemImage: "tuningfork")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    List {
        RepositoryRow(repo: .make())
        RepositoryRow(repo: .make(id: 2, name: "alamofire", fullName: "Alamofire/Alamofire",
                                  description: "Elegant HTTP Networking in Swift", language: "Swift"))
    }
    .listStyle(.plain)
}
#endif
