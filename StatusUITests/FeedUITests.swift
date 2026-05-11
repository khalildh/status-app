import XCTest

final class FeedUITests: StatusUITestCase {

    func testFeedTabShowsAfterSignIn() {
        launchSignedIn()
        XCTAssertTrue(app.navigationBars["Feed"].waitForExistence(timeout: 10))
    }

    func testFeedShowsStatusBalance() {
        launchSignedIn()
        XCTAssertTrue(app.navigationBars["Feed"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Status Balance"].waitForExistence(timeout: 5))
    }

    func testFeedShowsBroadcastButton() {
        launchSignedIn()
        XCTAssertTrue(app.navigationBars["Feed"].waitForExistence(timeout: 10))
        // The broadcast prompt or empty state should exist
        let broadcastPrompt = app.staticTexts["Broadcast to your audience"]
        let emptyState = app.staticTexts["No Broadcasts Yet"]
        _ = broadcastPrompt.waitForExistence(timeout: 5)
        XCTAssertTrue(broadcastPrompt.exists || emptyState.exists)
    }
}
