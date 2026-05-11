import XCTest

/// Base class for all Status UI tests.
/// Configures the app with --uitesting flag and resets state.
class StatusUITestCase: XCTestCase {
    var app: XCUIApplication!

    static let testEmail = "uitest@statusapp.test"
    static let testPassword = "StatusTest123!"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    // MARK: - Launch Helpers

    /// Launch fresh (shows onboarding)
    func launchFresh() {
        app.launchArguments += ["-hasSeenOnboarding", "NO"]
        app.launchArguments += ["-hasGivenFirstStatus", "NO"]
        app.launch()
    }

    /// Launch past onboarding (shows location gate or auth)
    func launchPastOnboarding() {
        app.launchArguments += ["-hasSeenOnboarding", "YES"]
        app.launchArguments += ["-hasGivenFirstStatus", "NO"]
        app.launch()
    }

    /// Launch at auth screen (onboarding + location done)
    func launchAtAuth() {
        app.launchArguments += ["-hasSeenOnboarding", "YES"]
        app.launchArguments += ["-hasGivenFirstStatus", "YES"]
        app.launch()
    }

    /// Launch and sign in with test account, landing on main app
    func launchSignedIn() {
        app.launchArguments += ["-hasSeenOnboarding", "YES"]
        app.launchArguments += ["-hasGivenFirstStatus", "YES"]
        app.launch()

        // Wait for auth screen
        guard app.textFields["Email"].waitForExistence(timeout: 10) else { return }

        // Sign in
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText(Self.testEmail)

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText(Self.testPassword)

        app.buttons["Sign In"].tap()

        // Wait for main app (Feed tab)
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 10)
    }
}
