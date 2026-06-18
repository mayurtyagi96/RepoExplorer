//
//  UserDefaultsSearchHistoryStore.swift
//  RepoExplorer
//
//  Persists recent searches as JSON in UserDefaults.
//

import Foundation

/// An `actor` so the read-modify-write of the recent list is one serialized critical section
/// (no lost-update races) and runs off the main actor.
///
/// Config is held as `nonisolated let` (all `Sendable`) so the initializer — inferred `@MainActor`
/// under the project's default isolation — can set it without touching actor-isolated state. The
/// `UserDefaults` is derived on demand from the suite name (instances are process-shared per suite).
actor UserDefaultsSearchHistoryStore: SearchHistoryStore {
    static let defaultKey = "recentSearches"

    private nonisolated let suiteName: String?
    private nonisolated let key: String
    private nonisolated let maxCount: Int

    init(suiteName: String? = nil, key: String = defaultKey, maxCount: Int = 20) {
        self.suiteName = suiteName
        self.key = key
        self.maxCount = maxCount
    }

    private var defaults: UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

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
