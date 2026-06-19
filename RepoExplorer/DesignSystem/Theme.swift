//
//  Theme.swift
//  RepoExplorer
//
//  Central design tokens: palette, spacing, and reusable view styling.
//

import SwiftUI

enum Theme {
    /// Brand accent (indigo) and its gradient end (violet).
    static let accent = Color(red: 0.357, green: 0.325, blue: 0.84)
    static let accentEnd = Color(red: 0.58, green: 0.30, blue: 0.86)

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accentEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Semantic stat colors.
    static let stars = Color(red: 0.97, green: 0.74, blue: 0.18)   // gold
    static let forks = Color(red: 0.27, green: 0.53, blue: 0.96)   // blue
    static let watchers = Color(red: 0.13, green: 0.66, blue: 0.60) // teal
    static let issues = Color(red: 0.95, green: 0.53, blue: 0.20)  // orange

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 20
    }

    static let cornerRadius: CGFloat = 16
}

extension View {
    /// Elevated card surface: padding, rounded background, hairline border, soft shadow.
    func repoCard(padding: CGFloat = Theme.Spacing.m) -> some View {
        self
            .padding(padding)
            .background(.background, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06))
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

/// Subtle scale-down on press, for tappable cards and buttons.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// Gentle pulse for skeleton placeholders.
private struct ShimmerModifier: ViewModifier {
    @State private var dim = false
    func body(content: Content) -> some View {
        content
            .opacity(dim ? 0.45 : 1)
            .animation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: dim)
            .onAppear { dim = true }
    }
}

extension View {
    func shimmering() -> some View { modifier(ShimmerModifier()) }
}
