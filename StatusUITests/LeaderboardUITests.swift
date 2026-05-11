import XCTest

final class LeaderboardUITests: StatusUITestCase {

    func testLeaderboardTabExists() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Leaderboard"].tap()
        XCTAssertTrue(app.navigationBars["Leaderboard"].waitForExistence(timeout: 5))
    }

    func testLeaderboardHasScopePicker() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Leaderboard"].tap()
        XCTAssertTrue(app.navigationBars["Leaderboard"].waitForExistence(timeout: 5))

        // Segmented control with scope options
        XCTAssertTrue(app.buttons["This Week"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["This Month"].exists)
        XCTAssertTrue(app.buttons["All Time"].exists)
    }

    func testLeaderboardScopeSwitching() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Leaderboard"].tap()
        XCTAssertTrue(app.buttons["This Week"].waitForExistence(timeout: 5))

        app.buttons["This Month"].tap()
        XCTAssertTrue(app.buttons["This Month"].isSelected)

        app.buttons["All Time"].tap()
        XCTAssertTrue(app.buttons["All Time"].isSelected)
    }
}
