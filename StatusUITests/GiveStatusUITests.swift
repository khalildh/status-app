import XCTest

final class GiveStatusUITests: StatusUITestCase {

    func testGiveStatusFromProfile() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Give Status"].waitForExistence(timeout: 5))
        app.buttons["Give Status"].tap()
        XCTAssertTrue(app.navigationBars["Give Status"].waitForExistence(timeout: 5))
    }

    func testGiveStatusShowsInviteOption() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Give Status"].waitForExistence(timeout: 5))
        app.buttons["Give Status"].tap()
        XCTAssertTrue(app.navigationBars["Give Status"].waitForExistence(timeout: 5))

        // Invite friends section should exist
        XCTAssertTrue(app.staticTexts["Invite Friends"].waitForExistence(timeout: 5))
    }

    func testGiveStatusHasSuggestedSection() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Give Status"].waitForExistence(timeout: 5))
        app.buttons["Give Status"].tap()
        XCTAssertTrue(app.navigationBars["Give Status"].waitForExistence(timeout: 5))

        // Should show Suggested section or Invite Friends
        let suggested = app.staticTexts["Suggested"]
        let invite = app.staticTexts["Invite Friends"]
        _ = suggested.waitForExistence(timeout: 5)
        XCTAssertTrue(suggested.exists || invite.exists)
    }

    func testGiveStatusFromLeaderboard() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Leaderboard"].tap()
        XCTAssertTrue(app.navigationBars["Leaderboard"].waitForExistence(timeout: 5))

        // Wait for leaderboard to load, then tap a row if available
        sleep(2) // Wait for Firestore data
        let cells = app.cells
        if cells.count > 0 {
            cells.firstMatch.tap()
            // Should navigate to give status
            XCTAssertTrue(app.navigationBars["Give Status"].waitForExistence(timeout: 5))
        }
    }

    func testGiveStatusAmountSelector() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()
        app.buttons["Give Status"].tap()
        XCTAssertTrue(app.navigationBars["Give Status"].waitForExistence(timeout: 5))

        // If there are suggested users, tap one to get to amount selector
        let cells = app.cells
        if cells.count > 0 {
            cells.firstMatch.tap()
            // Should see the amount selector
            XCTAssertTrue(app.staticTexts["Give Status"].waitForExistence(timeout: 5))
            // Plus and minus buttons should exist
            let plusButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'plus'")).firstMatch
            let minusButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'minus'")).firstMatch
            if plusButton.exists && minusButton.exists {
                // Tap plus to increase amount
                plusButton.tap()
                // Amount should change
                XCTAssertTrue(app.staticTexts["2"].waitForExistence(timeout: 3))
            }
        }
    }
}
