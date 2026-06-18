# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

RepoExplorer is a SwiftUI app for discovering GitHub repositories, built in phases as an MVVM app under Swift 6 strict concurrency. **Phases 1–3 (search + results list, metadata-only repo detail, persistent recent searches) are implemented and tested.** Planned next: Phase 4 (pagination/polish). No third-party dependencies — Foundation + SwiftUI + URLSession only. GitHub search is unauthenticated (the client has a token-injection seam for later).

## Toolchain

- Swift 6.0, Xcode 26.1+, iOS deployment target **26.1**, iPhone + iPad (`TARGETED_DEVICE_FAMILY = 1,2`).
- Pure SwiftUI app lifecycle (`@main RepoExplorerApp` → `WindowGroup` → `SearchView`); no AppDelegate/SceneDelegate, no UIKit.
- No dependency manager in use (no SPM packages, Podfile, or Cartfile). No linter/formatter or CI configured.

## Swift 6 concurrency (important)

The project builds with **`SWIFT_STRICT_CONCURRENCY = complete`** and **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`**. Practical consequences for any new code:
- Top-level declarations are implicitly `@MainActor` unless you opt out — UI code "just works" on the main actor, but background/async work must be explicitly moved off it (e.g. `nonisolated`, `Task.detached`, or actor-isolated types).
- Types crossing actor boundaries must be `Sendable`. Concurrency violations are hard errors, not warnings — assume the compiler will reject unsound code.

## Build

```bash
# Build for the simulator (pick an installed iOS 26 simulator; list them with the command below)
xcodebuild build -project RepoExplorer.xcodeproj -scheme RepoExplorer \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# List available simulator/device destinations
xcodebuild -project RepoExplorer.xcodeproj -scheme RepoExplorer -showdestinations

# Clean
xcodebuild clean -project RepoExplorer.xcodeproj -scheme RepoExplorer
```

## Test

Tests use **XCTest** (not Swift Testing). Unit tests live in `RepoExplorerTests/`; UI tests in `RepoExplorerUITests/`.

```bash
# All tests
xcodebuild test -project RepoExplorer.xcodeproj -scheme RepoExplorer \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Only unit tests (or only UI tests: RepoExplorerUITests)
xcodebuild test -project RepoExplorer.xcodeproj -scheme RepoExplorer \
  -only-testing:RepoExplorerTests \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# A single test method — -only-testing:<Target>/<Class>/<method>
xcodebuild test -project RepoExplorer.xcodeproj -scheme RepoExplorer \
  -only-testing:RepoExplorerTests/SearchViewModelTests/test_search_success_setsLoaded \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Reuse a fixed `-derivedDataPath` (e.g. `/tmp/RepoExplorer-DD`) across runs for fast incremental builds. The only expected build warning is a benign `appintentsmetadataprocessor` "No AppIntents.framework dependency" line.

## Architecture (MVVM)

Clean separation of View ↔ ViewModel ↔ services, with services behind `Sendable` protocols so they are mockable. New `.swift` files are picked up automatically — the Xcode targets use `PBXFileSystemSynchronizedRootGroup`, so **do not edit `project.pbxproj` to add files**; just create them under the target folder.

- `RepoExplorer/App/AppDependencies.swift` — composition root; `.live` builds the real client + UserDefaults history store and `makeSearchViewModel()`. `current()` swaps in canned data on an isolated UserDefaults suite when launched with `-uiTestStubResults` (and pre-seeds recent searches with `-uiTestSeedHistory`); used by `RepoExplorerUITests`.
- `RepoExplorer/Models/` — `Repository` (+ `Owner`, `License`), `SearchResponse`, `GitHubAPIError`, `RecentSearch`. Immutable `Decodable/Codable, Sendable` structs.
- `RepoExplorer/Networking/` — `GitHubAPIClient` (protocol) + `LiveGitHubAPIClient` (URLSession).
- `RepoExplorer/Persistence/` — `SearchHistoryStore` (protocol, `Sendable`/`nonisolated` reqs) + `UserDefaultsSearchHistoryStore` (persisting `actor`) and `InMemorySearchHistoryStore` (the VM's default, for previews/tests). Case-insensitive dedup + MRU + cap shared via the `recentSearches(byInserting:…)` helper. Stores only `{query, date}` — API results are intentionally **not** cached; tapping a recent search re-fetches live.
- `RepoExplorer/ViewModels/SearchViewModel.swift` — `@MainActor @Observable`; owns `query`, `repos`, a `status` state enum, and `recent` (history). Debounced + generation-guarded search; `retry()`/`selectRecent()` (immediate re-run); `loadHistory`/`clearHistory`/`removeRecent`.
- `RepoExplorer/Views/` — `SearchView` (root; `.searchable` + `.task(id:)`; `NavigationStack` + `.navigationDestination(for: Repository.self)`; recent-searches list in the idle state), `RepositoryRow`, `RepositoryDetailView` (metadata-only), `ErrorStateView`, `Components/AvatarView`, `Components/FlowLayout` (wrapping chips).
- `RepoExplorer/Extensions/` — small shared helpers (e.g. `Int.formattedCompact`).
- `RepoExplorer/PreviewSupport.swift` — `#if DEBUG` sample data + factories (`.make()`, `.samples`), reused by previews and tests via `@testable`.
- `RepoExplorerTests/` — XCTest. `@MainActor`-annotated test classes; mocks in `Support/` (`StubGitHubAPIClient`, `actor SpyGitHubAPIClient`, `SequencedGitHubAPIClient`, `CancellationIgnoringClient`, `MockURLProtocol`, `JSONFixtures`). UI tests drive deterministic, network-free flows via the `-uiTestStubResults` / `-uiTestSeedHistory` launch args.

## Concurrency conventions (non-negotiable under these build settings)

`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` + `SWIFT_APPROACHABLE_CONCURRENCY = YES` make these subtle. Follow the established patterns:

- **Off-main work needs `@concurrent`, not just `nonisolated`.** A bare `nonisolated async` func runs on the *caller's* actor (= main when called from the VM). `LiveGitHubAPIClient.searchRepositories` is `@concurrent nonisolated` so request building + decode run off-main. `Sendable` alone does **not** move a type off the main actor.
- **Model/service types are declared `nonisolated`** so their `Decodable` conformances are usable from off-main decoding (otherwise: `#IsolatedConformances` error). Protocol requirements crossing into the VM are `nonisolated`.
- **`SearchViewModel` is `@MainActor` and never `Sendable`/`@unchecked Sendable`.** UI state mutates only on main; values crossing in are immutable `Sendable` structs.
- **Cancellation is structured + generation-guarded:** the View drives searches via `.task(id:)` (cancels on query change and disappear); the VM debounces *inline* with `Task.sleep` (no inner unstructured `Task`). Each `search()` stamps a `generation` token and guards every state write with `guard token == generation`, so a superseded task can't overwrite newer state; on `CancellationError` it derives a stable `status` (never strands `.loading`). Search history is recorded only on a committed search that is neither cancelled (`!Task.isCancelled`) nor superseded.
- **Don't mutate `@Observable` state from multiple unstructured `Task {}` via a store read-back** — their `@MainActor` continuations can resolve out of order and republish a stale value. Mutate the published state optimistically (synchronously on the main actor) and persist afterward; see `removeRecent`/`clearHistory`.
- **No Combine, no GCD/DispatchQueue.** Use async/await, actors, `Task`, `Task.sleep`.
- **Decoding:** explicit snake_case `CodingKeys` (not `.convertFromSnakeCase`, which breaks `htmlURL`/`avatarURL`/`spdxID`).
- **`@MainActor` test methods must be `async`** — a synchronous `@MainActor` XCTest method can be invoked off-main and trap.
- **Actors are constructed on the main actor.** Under default `MainActor` isolation an `actor`'s initializer is inferred `@MainActor` (and you can't mark an actor's sync init `nonisolated`), so build actor-backed stores from a main-actor context — their *methods* still run off-main. Keep immutable actor config as `nonisolated let` (Sendable types) so the init can set it without touching actor-isolated state; tests that construct an actor directly should be `@MainActor`.
