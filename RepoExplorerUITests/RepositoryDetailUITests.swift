//
//  RepositoryDetailUITests.swift
//  RepoExplorerUITests
//
//  End-to-end: search -> tap a result -> repository detail. Uses the `-uiTestStubResults`
//  launch argument so the app serves canned data without hitting the network.
//

import XCTest

final class RepositoryDetailUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_tappingResult_opensRepositoryDetail() {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTestStubResults")
        app.launch()

        // Focus the search field and type a query — the stubbed client returns sample repos.
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10), "search field should appear")
        searchField.tap()
        searchField.typeText("swift")

        // A result row (sample data) appears.
        let row = app.staticTexts["apple/swift"]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "result row should appear")
        app.cells.firstMatch.tap()

        // The metadata detail screen shows its primary action.
        XCTAssertTrue(app.buttons["Open in GitHub"].waitForExistence(timeout: 10),
                      "detail screen should show the Open in GitHub action")
    }
}
