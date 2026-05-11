import XCTest

final class ProfileUITests: StatusUITestCase {

    func testProfileTabExists() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
    }

    func testProfileShowsStats() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))

        // Stats cards should exist
        XCTAssertTrue(app.staticTexts["Balance"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Received"].exists)
        XCTAssertTrue(app.staticTexts["Rank"].exists)
    }

    func testProfileShowsActions() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))

        XCTAssertTrue(app.buttons["Give Status"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Buy More Points"].exists)
        XCTAssertTrue(app.buttons["Status History"].exists)
        XCTAssertTrue(app.buttons["Sign Out"].exists)
    }

    func testGiveStatusNavigation() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Give Status"].waitForExistence(timeout: 5))
        app.buttons["Give Status"].tap()
        XCTAssertTrue(app.navigationBars["Give Status"].waitForExistence(timeout: 5))
    }

    func testStatusHistoryNavigation() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Status History"].waitForExistence(timeout: 5))
        app.buttons["Status History"].tap()
        XCTAssertTrue(app.navigationBars["Status History"].waitForExistence(timeout: 5))
    }

    func testBuyMorePointsOpensStore() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Buy More Points"].waitForExistence(timeout: 5))
        app.buttons["Buy More Points"].tap()
        XCTAssertTrue(app.staticTexts["Get More Status"].waitForExistence(timeout: 5))
    }

    func testSignOut() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()

        // Scroll down to find Sign Out
        let signOutButton = app.buttons["Sign Out"]
        if !signOutButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5))
        signOutButton.tap()

        // Should return to auth screen
        XCTAssertTrue(app.textFields["Email"].waitForExistence(timeout: 10))
    }

    func testEditProfileNavigation() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))

        // Tap edit button in toolbar
        app.navigationBars["Profile"].buttons.matching(identifier: "pencil.circle").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Edit Profile"].waitForExistence(timeout: 5))
    }
}
