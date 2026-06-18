//
//  RepositoryDetailView.swift
//  RepoExplorer
//
//  Metadata-only repository detail, rendered entirely from the already-fetched
//  `Repository` value — no additional network requests.
//

import SwiftUI

struct RepositoryDetailView: View {
    let repo: Repository

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let description = repo.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                statsRow
                metadataRows

                if !repo.topicList.isEmpty {
                    topicsSection
                }

                if let url = repo.webURL {
                    Link(destination: url) {
                        Label("Open in GitHub", systemImage: "arrow.up.forward.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(repo.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 12) {
            AvatarView(url: repo.owner?.avatarImageURL, size: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(repo.fullName)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                if let owner = repo.owner {
                    Text("@\(owner.login)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var statsRow: some View {
        HStack {
            stat(repo.stargazersCount, "Stars", "star.fill")
            statDivider
            stat(repo.forksCount, "Forks", "tuningfork")
            statDivider
            stat(repo.watchersCount, "Watchers", "eye.fill")
            statDivider
            stat(repo.openIssuesCount, "Issues", "exclamationmark.circle")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func stat(_ value: Int, _ label: String, _ systemImage: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage).font(.headline)
            Text(value.formattedCompact)
                .font(.headline)
                .monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View { Divider().frame(height: 36) }

    @ViewBuilder
    private var metadataRows: some View {
        VStack(spacing: 0) {
            if let language = repo.language, !language.isEmpty {
                metadataRow("Language", value: language, systemImage: "chevron.left.forwardslash.chevron.right")
            }
            if let license = repo.license {
                metadataRow("License", value: license.shortName, systemImage: "doc.text")
            }
            if let updated = repo.updatedDate {
                metadataRow("Last updated",
                            value: updated.formatted(.relative(presentation: .named)),
                            systemImage: "clock")
            }
        }
    }

    private func metadataRow(_ title: String, value: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Topics").font(.headline)
            FlowLayout(spacing: 8) {
                ForEach(repo.topicList, id: \.self) { topic in
                    Text(topic)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.tint.opacity(0.15), in: Capsule())
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        RepositoryDetailView(repo: .make())
    }
}
#endif
