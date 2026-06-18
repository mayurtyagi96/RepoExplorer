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
                AsyncImage(url: repo.owner?.avatarImageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.secondary.opacity(0.2)
                }
                .frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 5))

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
                Label(repo.stargazersCount.formatted(.number.notation(.compactName)),
                      systemImage: "star.fill")
                if let language = repo.language, !language.isEmpty {
                    Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Label(repo.forksCount.formatted(.number.notation(.compactName)),
                      systemImage: "tuningfork")
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
