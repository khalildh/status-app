import XCTest

final class BroadcastUITests: StatusUITestCase {

    func testComposeBroadcastOpens() {
        launchSignedIn()
        XCTAssertTrue(app.navigationBars["Feed"].waitForExistence(timeout: 10))

        // Tap broadcast prompt
        let prompt = app.staticTexts["Broadcast to your audience"]
        if prompt.waitForExistence(timeout: 5) {
            prompt.tap()
            XCTAssertTrue(app.navigationBars["New Broadcast"].waitForExistence(timeout: 5))
        }
    }

    func testComposeBroadcastCancel() {
        launchSignedIn()
        XCTAssertTrue(app.navigationBars["Feed"].waitForExistence(timeout: 10))

        let prompt = app.staticTexts["Broadcast to your audience"]
        if prompt.waitForExistence(timeout: 5) {
            prompt.tap()
            XCTAssertTrue(app.navigationBars["New Broadcast"].waitForExistence(timeout: 5))
            app.buttons["Cancel"].tap()
            // Should be back on feed
            XCTAssertTrue(app.navigationBars["Feed"].waitForExistence(timeout: 5))
        }
    }

    func testComposeBroadcastDisabledWhenEmpty() {
        launchSignedIn()
        XCTAssertTrue(app.navigationBars["Feed"].waitForExistence(timeout: 10))

        let prompt = app.staticTexts["Broadcast to your audience"]
        if prompt.waitForExistence(timeout: 5) {
            prompt.tap()
            XCTAssertTrue(app.navigationBars["New Broadcast"].waitForExistence(timeout: 5))
            // Broadcast button should be disabled with empty text
            XCTAssertFalse(app.buttons["Broadcast"].isEnabled)
        }
    }

    func testComposeBroadcastEnabledWithText() {
        launchSignedIn()
        XCTAssertTrue(app.navigationBars["Feed"].waitForExistence(timeout: 10))

        let prompt = app.staticTexts["Broadcast to your audience"]
        if prompt.waitForExistence(timeout: 5) {
            prompt.tap()
            XCTAssertTrue(app.navigationBars["New Broadcast"].waitForExistence(timeout: 5))

            // Type a message
            let textEditor = app.textViews.firstMatch
            textEditor.tap()
            textEditor.typeText("Testing broadcast from UI tests")

            XCTAssertTrue(app.buttons["Broadcast"].isEnabled)
        }
    }

    func testCharacterCountShows() {
        launchSignedIn()
        XCTAssertTrue(app.navigationBars["Feed"].waitForExistence(timeout: 10))

        let prompt = app.staticTexts["Broadcast to your audience"]
        if prompt.waitForExistence(timeout: 5) {
            prompt.tap()
            XCTAssertTrue(app.navigationBars["New Broadcast"].waitForExistence(timeout: 5))
            // Character count should show 0/280
            XCTAssertTrue(app.staticTexts["0/280"].waitForExistence(timeout: 3))
        }
    }
}
