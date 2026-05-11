import XCTest

final class MainTabUITests: StatusUITestCase {

    func testAppLaunchesSuccessfully() {
        launchAtAuth()
        // App should launch without crashing and show auth or main screen
        let emailField = app.textFields["Email"]
        let statusText = app.staticTexts["Status"]
        _ = emailField.waitForExistence(timeout: 10)
        XCTAssertTrue(emailField.exists || statusText.exists)
    }

    func testAllTabsAccessible() {
        launchSignedIn()
        guard app.tabBars.firstMatch.waitForExistence(timeout: 15) else {
            XCTFail("Could not sign in to reach tab bar")
            return
        }

        // Feed tab (default)
        XCTAssertTrue(app.navigationBars["Feed"].waitForExistence(timeout: 5))

        // Messages tab
        app.tabBars.buttons["Messages"].tap()
        XCTAssertTrue(app.navigationBars["Messages"].waitForExistence(timeout: 5))

        // Leaderboard tab
        app.tabBars.buttons["Leaderboard"].tap()
        XCTAssertTrue(app.navigationBars["Leaderboard"].waitForExistence(timeout: 5))

        // Profile tab
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
    }
}
