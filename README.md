# RepoExplorer

A small SwiftUI iOS app for discovering open-source projects on GitHub. Search for a topic or
library, browse the results, tap a repository to see its details, and the app remembers your recent
searches across launches.

## Features

- **Search** GitHub repositories (search-as-you-type, debounced, with in-flight request cancellation).
- **Browse** results in a list — name, owner, description, stars, language, forks.
- **Detail** screen with full metadata: stars / forks / watchers / open issues, language, license,
  topics, last-updated, and an "Open in GitHub" link.
- **Recent searches** persisted across app relaunch — tap to re-run, swipe to delete, or clear all.

## Requirements

- **Xcode 26.1+** (Swift 6 toolchain)
- **iOS 26.1** simulator or device
- No third-party dependencies — Foundation + SwiftUI + URLSession only. Nothing to install.

GitHub's search API is called **unauthenticated**, which is rate-limited to ~10 searches/minute —
plenty for normal use, but rapid repeated searching may briefly hit the limit (shown as a friendly
error with a Retry button).

## Run it

### Xcode (recommended)

1. Open `RepoExplorer.xcodeproj` in Xcode 26.1+.
2. Select the **RepoExplorer** scheme and an iOS 26 simulator (e.g. **iPhone 17**), or a connected device.
3. Press **⌘R**.

> Running on a physical device requires selecting your own signing team in
> *Signing & Capabilities* (the project ships with a placeholder team).

### Command line

```bash
# Build for a simulator (list installed ones with:
#   xcodebuild -project RepoExplorer.xcodeproj -scheme RepoExplorer -showdestinations)
xcodebuild build -project RepoExplorer.xcodeproj -scheme RepoExplorer \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Boot the simulator and launch the built app
open -a Simulator
xcrun simctl install booted \
  ~/Library/Developer/Xcode/DerivedData/RepoExplorer-*/Build/Products/Debug-iphonesimulator/RepoExplorer.app
xcrun simctl launch booted com.mayur.RepoExplorer
```

## Tests

```bash
# All tests (unit + UI)
xcodebuild test -project RepoExplorer.xcodeproj -scheme RepoExplorer \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Unit tests only
xcodebuild test -project RepoExplorer.xcodeproj -scheme RepoExplorer \
  -only-testing:RepoExplorerTests \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

In Xcode, press **⌘U** to run the test suite.

## Architecture

MVVM under **Swift 6 strict concurrency** (no Combine, no GCD):

- **Models** — immutable `Sendable` Codable structs for the GitHub responses.
- **Networking** — a `GitHubAPIClient` protocol + a `URLSession`-backed implementation that runs off
  the main actor.
- **Persistence** — a `SearchHistoryStore` actor backed by `UserDefaults` (stores recent query
  strings, not results).
- **ViewModel** — a `@MainActor @Observable` `SearchViewModel` owning all UI state.
- **Views** — SwiftUI screens (`SearchView`, `RepositoryDetailView`, …).

See [`CLAUDE.md`](CLAUDE.md) for the detailed architecture and concurrency conventions.


## Next To Do - 


## Assumption to -
 

## Questions about product -

