//
//  AvatarView.swift
//  RepoExplorer
//
//  Rounded owner/repository avatar with a neutral placeholder.
//

import SwiftUI

struct AvatarView: View {
    let url: URL?
    var size: CGFloat

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.secondary.opacity(0.2)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}
