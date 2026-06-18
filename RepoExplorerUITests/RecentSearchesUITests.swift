//
//  RecentSearchesUITests.swift
//  RepoExplorerUITests
//
//  Phase 3: recent searches appear on the idle screen and re-run when tapped.
//  `-uiTestSeedHistory` pre-populates history so the flow is deterministic and network-free.
//

import XCTest

final class RecentSearchesUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_tappingRecentSearch_runsItAgain() {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestStubResults", "-uiTestSeedHistory"]
        app.launch()

        // The idle screen shows the seeded recent searches.
        let recent = app.buttons["swift"]
        XCTAssertTrue(recent.waitForExistence(timeout: 10), "a seeded recent search should appear")

        // Tapping a recent search re-runs it and shows results.
        recent.tap()
        XCTAssertTrue(app.staticTexts["apple/swift"].waitForExistence(timeout: 10),
                      "tapping a recent search should re-run it and show results")
    }
}
