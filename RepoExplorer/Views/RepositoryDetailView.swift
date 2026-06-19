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

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                header

                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    if let description = repo.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    statsGrid
                    metadataCard

                    if !repo.topicList.isEmpty {
                        topicsSection
                    }

                    if let url = repo.webURL {
                        openInGitHubButton(url)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, Theme.Spacing.l)
            }
        }
        .navigationTitle(repo.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.m) {
            AvatarView(url: repo.owner?.avatarImageURL, size: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 72 * 0.22, style: .continuous)
                        .strokeBorder(.white.opacity(0.6), lineWidth: 1.5)
                )

            VStack(spacing: 2) {
                Text(repo.fullName)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                if let owner = repo.owner {
                    Text("@\(owner.login)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.l)
        .padding(.horizontal)
        .background(Theme.accentGradient)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 28, bottomTrailingRadius: 28, style: .continuous))
    }

    // MARK: Stats

    private var statsGrid: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.m) {
            statPill(repo.stargazersCount, "Stars", "star.fill", Theme.stars)
            statPill(repo.forksCount, "Forks", "tuningfork", Theme.forks)
            statPill(repo.watchersCount, "Watchers", "eye.fill", Theme.watchers)
            statPill(repo.openIssuesCount, "Issues", "exclamationmark.circle.fill", Theme.issues)
        }
    }

    private func statPill(_ value: Int, _ label: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(value.formattedCompact).font(.headline).monospacedDigit()
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .repoCard()
    }

    // MARK: Metadata

    private var metadataCard: some View {
        VStack(spacing: 0) {
            if let language = repo.language, !language.isEmpty {
                metadataRow("Language", value: language, systemImage: "chevron.left.forwardslash.chevron.right", divider: true)
            }
            if let license = repo.license {
                metadataRow("License", value: license.shortName, systemImage: "doc.text",
                            divider: repo.updatedDate != nil)
            }
            if let updated = repo.updatedDate {
                metadataRow("Last updated",
                            value: updated.formatted(.relative(presentation: .named)),
                            systemImage: "clock", divider: false)
            }
        }
        .repoCard(padding: Theme.Spacing.s)
    }

    private func metadataRow(_ title: String, value: String, systemImage: String, divider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 22)
                Text(title).foregroundStyle(.secondary)
                Spacer()
                Text(value).multilineTextAlignment(.trailing)
            }
            .font(.subheadline)
            .padding(.vertical, Theme.Spacing.s)
            if divider { Divider() }
        }
    }

    // MARK: Topics

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Topics").font(.headline)
            FlowLayout(spacing: Theme.Spacing.s) {
                ForEach(repo.topicList, id: \.self) { topic in
                    Text(topic)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.accent.opacity(0.14), in: Capsule())
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    // MARK: Action

    private func openInGitHubButton(_ url: URL) -> some View {
        Link(destination: url) {
            Label("Open in GitHub", systemImage: "arrow.up.forward.square")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(.white)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        RepositoryDetailView(repo: .make())
    }
}
#endif
