# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

RepoExplorer is a SwiftUI app for discovering GitHub repositories, built in phases as an MVVM app under Swift 6 strict concurrency. **Phase 1 (search + results list) is implemented and tested.** Planned next: Phase 2 (metadata-only repo detail screen), Phase 3 (persistent recent searches via a UserDefaults-backed actor), Phase 4 (pagination/polish). No third-party dependencies — Foundation + SwiftUI + URLSession only. GitHub search is unauthenticated (the client has a token-injection seam for later).

## Toolchain

- Swift 6.0, Xcode 26.1+, iOS deployment target **26.1**, iPhone + iPad (`TARGETED_DEVICE_FAMILY = 1,2`).
- Pure SwiftUI app lifecycle (`@main RepoExplorerApp` → `WindowGroup` → `ContentView`); no AppDelegate/SceneDelegate, no UIKit.
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
  -only-testing:RepoExplorerTests/RepoExplorerTests/testExample \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Architecture (MVVM)

Clean separation of View ↔ ViewModel ↔ services, with services behind `Sendable` protocols so they are mockable. New `.swift` files are picked up automatically — the Xcode targets use `PBXFileSystemSynchronizedRootGroup`, so **do not edit `project.pbxproj` to add files**; just create them under the target folder.

- `RepoExplorer/App/AppDependencies.swift` — composition root; `.live` builds the real client and `makeSearchViewModel()`.
- `RepoExplorer/Models/` — `Repository` (+ `Owner`, `License`), `SearchResponse`, `GitHubAPIError`. Immutable `Decodable, Sendable` structs.
- `RepoExplorer/Networking/` — `GitHubAPIClient` (protocol) + `LiveGitHubAPIClient` (URLSession).
- `RepoExplorer/ViewModels/SearchViewModel.swift` — `@MainActor @Observable`; owns `query`, `repos`, and a `status` state enum.
- `RepoExplorer/Views/` — `SearchView` (root; `.searchable` + `.task(id:)`), `RepositoryRow`, `ErrorStateView`.
- `RepoExplorer/PreviewSupport.swift` — `#if DEBUG` sample data + factories (`.make()`, `.samples`), reused by previews and tests via `@testable`.
- `RepoExplorerTests/` — XCTest. `@MainActor`-annotated VM test classes; mocks in `Support/` (`StubGitHubAPIClient`, `actor SpyGitHubAPIClient`, `MockURLProtocol`, `JSONFixtures`).

## Concurrency conventions (non-negotiable under these build settings)

`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` + `SWIFT_APPROACHABLE_CONCURRENCY = YES` make these subtle. Follow the established patterns:

- **Off-main work needs `@concurrent`, not just `nonisolated`.** A bare `nonisolated async` func runs on the *caller's* actor (= main when called from the VM). `LiveGitHubAPIClient.searchRepositories` is `@concurrent nonisolated` so request building + decode run off-main. `Sendable` alone does **not** move a type off the main actor.
- **Model/service types are declared `nonisolated`** so their `Decodable` conformances are usable from off-main decoding (otherwise: `#IsolatedConformances` error). Protocol requirements crossing into the VM are `nonisolated`.
- **`SearchViewModel` is `@MainActor` and never `Sendable`/`@unchecked Sendable`.** UI state mutates only on main; values crossing in are immutable `Sendable` structs.
- **Cancellation is structured:** the View drives searches via `.task(id:)` (which cancels on query change and on disappear); the VM debounces *inline* with `Task.sleep` (no inner unstructured `Task`), checks `Task.checkCancellation()` before mutating state, and derives a stable `status` on `CancellationError` (never strands `.loading`).
- **No Combine, no GCD/DispatchQueue.** Use async/await, actors, `Task`, `Task.sleep`.
- **Decoding:** explicit snake_case `CodingKeys` (not `.convertFromSnakeCase`, which breaks `htmlURL`/`avatarURL`/`spdxID`).
- **`@MainActor` test methods must be `async`** — a synchronous `@MainActor` XCTest method can be invoked off-main and trap.
