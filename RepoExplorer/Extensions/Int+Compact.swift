//
//  Int+Compact.swift
//  RepoExplorer
//

import Foundation

extension Int {
    /// Compact, locale-aware display of a count (e.g. 1234 -> "1.2K").
    var formattedCompact: String { formatted(.number.notation(.compactName)) }
}
