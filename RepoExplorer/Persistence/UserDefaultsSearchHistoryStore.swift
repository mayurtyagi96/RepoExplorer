//
//  UserDefaultsSearchHistoryStore.swift
//  RepoExplorer
//
//  Persists recent searches as JSON in UserDefaults.
//

import Foundation

/// An `actor` so the read-modify-write of the recent list is one serialized critical section
/// (no lost-update races) and runs off the main actor. Persists to the app's standard
/// `UserDefaults`.
actor UserDefaultsSearchHistoryStore: SearchHistoryStore {
    private let key = "recentSearches"
    private let maxCount = 20
    private let defaults = UserDefaults.standard

    func recent() -> [RecentSearch] { load() }

    func record(_ query: String) {
        save(recentSearches(byInserting: query, into: load(), maxCount: maxCount, now: Date()))
    }

    func remove(_ query: String) {
        save(load().filter { $0.query.caseInsensitiveCompare(query) != .orderedSame })
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }

    private func load() -> [RecentSearch] {
        guard let data = defaults.data(forKey: key),
              let entries = try? JSONDecoder().decode([RecentSearch].self, from: data)
        else { return [] }
        return entries
    }

    private func save(_ entries: [RecentSearch]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: key)
        }
    }
}
