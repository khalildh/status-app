import XCTest

final class MessagesUITests: StatusUITestCase {

    func testMessagesTabExists() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Messages"].tap()
        XCTAssertTrue(app.navigationBars["Messages"].waitForExistence(timeout: 5))
    }

    func testMessagesShowsEmptyState() {
        launchSignedIn()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons["Messages"].tap()
        // New test account should have no messages
        let emptyState = app.staticTexts["No Messages Yet"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5))
    }
}
