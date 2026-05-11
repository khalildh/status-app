import XCTest

final class AuthUITests: StatusUITestCase {

    func testAuthScreenShowsSignIn() {
        launchAtAuth()
        XCTAssertTrue(app.staticTexts["Status"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your social capital, quantified."].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.buttons["Sign In"].exists)
    }

    func testToggleToSignUp() {
        launchAtAuth()
        XCTAssertTrue(app.staticTexts["Status"].waitForExistence(timeout: 5))

        // Tap "Don't have an account? Sign Up"
        app.buttons["Don't have an account? Sign Up"].tap()

        // Should now show Username field and Create Account button
        XCTAssertTrue(app.textFields["Username"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Create Account"].exists)
    }

    func testToggleBackToSignIn() {
        launchAtAuth()
        XCTAssertTrue(app.staticTexts["Status"].waitForExistence(timeout: 5))

        app.buttons["Don't have an account? Sign Up"].tap()
        XCTAssertTrue(app.textFields["Username"].waitForExistence(timeout: 3))

        app.buttons["Already have an account? Sign In"].tap()
        XCTAssertTrue(app.buttons["Sign In"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["Username"].exists)
    }

    func testSignInButtonDisabledWhenEmpty() {
        launchAtAuth()
        XCTAssertTrue(app.buttons["Sign In"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Sign In"].isEnabled)
    }

    func testSignInButtonEnabledWithInput() {
        launchAtAuth()
        XCTAssertTrue(app.textFields["Email"].waitForExistence(timeout: 5))

        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("test@test.com")
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("password123")

        XCTAssertTrue(app.buttons["Sign In"].isEnabled)
    }

    func testCreateAccountDisabledWithoutUsername() {
        launchAtAuth()
        XCTAssertTrue(app.staticTexts["Status"].waitForExistence(timeout: 5))

        app.buttons["Don't have an account? Sign Up"].tap()
        XCTAssertTrue(app.textFields["Email"].waitForExistence(timeout: 3))

        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("test@test.com")
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("password123")

        // Username is empty, button should be disabled
        XCTAssertFalse(app.buttons["Create Account"].isEnabled)
    }
}
