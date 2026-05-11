import XCTest

final class OnboardingUITests: StatusUITestCase {

    func testOnboardingShowsFirstPage() {
        launchFresh()
        XCTAssertTrue(app.staticTexts["Give Status"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Next"].exists)
    }

    func testSwipeThroughAllPages() {
        launchFresh()

        // Page 1
        XCTAssertTrue(app.staticTexts["Give Status"].waitForExistence(timeout: 5))
        app.buttons["Next"].tap()

        // Page 2
        XCTAssertTrue(app.staticTexts["Unlock Messaging"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()

        // Page 3
        XCTAssertTrue(app.staticTexts["Broadcast Daily"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()

        // Page 4
        XCTAssertTrue(app.staticTexts["Climb the Leaderboard"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Get Started"].exists)
    }

    func testGetStartedDismissesOnboarding() {
        launchFresh()

        // Tap through all pages
        XCTAssertTrue(app.staticTexts["Give Status"].waitForExistence(timeout: 5))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Unlock Messaging"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Broadcast Daily"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Climb the Leaderboard"].waitForExistence(timeout: 3))
        app.buttons["Get Started"].tap()

        // Should no longer show onboarding content
        let onboardingGone = app.staticTexts["Give Status"].waitForNonExistence(timeout: 5)
        XCTAssertTrue(onboardingGone)
    }

    func testSkipsOnboardingWhenAlreadySeen() {
        launchPastOnboarding()
        // Should NOT show onboarding
        XCTAssertFalse(app.staticTexts["Give Status"].waitForExistence(timeout: 2))
    }
}
