import XCTest

final class LocationGateUITests: StatusUITestCase {

    func testLocationGateBypassedInUITesting() {
        // With --uitesting, location gate should be bypassed
        launchPastOnboarding()

        // Should NOT see "Not Available Yet" or location gate
        XCTAssertFalse(app.staticTexts["Not Available Yet"].waitForExistence(timeout: 2))

        // Should see auth screen (location gate bypassed)
        XCTAssertTrue(
            app.staticTexts["Your social capital, quantified."].waitForExistence(timeout: 5) ||
            app.textFields["Email"].waitForExistence(timeout: 5)
        )
    }
}
