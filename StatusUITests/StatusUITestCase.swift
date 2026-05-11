import XCTest

/// Base class for all Status UI tests.
/// Configures the app with --uitesting flag and resets state.
class StatusUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        // Reset UserDefaults for clean state
        app.launchArguments += ["-hasSeenOnboarding", "NO"]
        app.launchArguments += ["-hasGivenFirstStatus", "NO"]
    }

    /// Launch with onboarding already completed
    func launchPastOnboarding() {
        app.launchArguments += ["-hasSeenOnboarding", "YES"]
        app.launch()
    }

    /// Launch with onboarding + first status completed (goes to auth)
    func launchAtAuth() {
        app.launchArguments += ["-hasSeenOnboarding", "YES"]
        app.launchArguments += ["-hasGivenFirstStatus", "YES"]
        app.launch()
    }

    /// Launch from the very beginning (onboarding)
    func launchFresh() {
        app.launch()
    }
}
