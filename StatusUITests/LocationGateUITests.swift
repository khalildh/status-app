import XCTest

final class LocationGateUITests: StatusUITestCase {

    func testLocationGateBypassedInUITesting() {
        // With --uitesting, location gate should be bypassed
        // App should reach auth screen, not location gate
        launchAtAuth()

        // Should see auth screen elements (email field or Status text)
        let emailField = app.textFields["Email"]
        let statusText = app.staticTexts["Status"]
        _ = emailField.waitForExistence(timeout: 10)
        XCTAssertTrue(emailField.exists || statusText.exists)
    }
}
