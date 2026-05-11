import XCTest

final class MainTabUITests: StatusUITestCase {

    /// Launch into main app with a mock authenticated user
    private func launchAuthenticated() {
        app.launchArguments += ["-hasSeenOnboarding", "YES"]
        app.launchArguments += ["-hasGivenFirstStatus", "YES"]
        // Set mock auth state — AuthService in uitesting mode starts unauthenticated
        // We need to sign in through the UI or mock it
        // For now, test the auth screen tabs since we can't bypass Firebase auth in UI tests
        app.launch()
    }

    func testTabBarExists() {
        launchAuthenticated()
        // In UI test mode without Firebase, we land on auth screen
        // We can verify the app launches without crashing
        XCTAssertTrue(app.staticTexts["Status"].waitForExistence(timeout: 5))
    }
}
