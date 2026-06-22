//
//  PermissionUITestCase.swift
//  Go CyclingUITests
//

import XCTest

/// Base class for tests that exercise the real system location permission prompt.
///
/// Run with the **Go Cycling UI Permission** scheme (⌘U). Its Test pre-action
/// resets location on the default UI-test iPhone simulator. Pick the same
/// iPhone in Xcode's destination menu (see `ui-test-simulator-udid.sh`).
class PermissionUITestCase: XCTestCase {
  private let appLauncher = AppLauncher()
  private(set) var app: XCUIApplication?
  private(set) var permissionPromptObserved = false

  override func setUpWithError() throws {
    continueAfterFailure = false
    permissionPromptObserved = false

    addUIInterruptionMonitor(withDescription: "System location permission") {
      [weak self] alert in
      guard SystemLocationAlert.isLocationPermissionAlert(alert) else { return false }
      guard SystemLocationAlert.dismiss(alert: alert, preferDeny: true) else { return false }
      self?.permissionPromptObserved = true
      return true
    }
  }

  override func tearDownWithError() throws {
    SystemLocationAlert.dismissIfPresent(app: app, preferDeny: true)
    app?.terminate()
    app = nil
  }

  @discardableResult
  func launchAppExpectingPermissionPrompt(
    extraArguments: [String] = [],
    environment: [String: String] = [:]
  ) -> XCUIApplication {
    app?.terminate()
    let launchedApp = appLauncher.launch(
      extraArguments: extraArguments,
      environment: environment
    )
    app = launchedApp
    return launchedApp
  }

  /// Triggers XCTest interruption-monitor handling for any blocking system alert.
  ///
  /// The app requests when-in-use and always authorization at launch, so iOS may
  /// present more than one system sheet before the cycle screen is tappable.
  func triggerInterruptionMonitor(on app: XCUIApplication, maxAttempts: Int = 3) {
    for _ in 0..<maxAttempts {
      if app.buttons.firstMatch.waitForExistence(timeout: 1) {
        app.buttons.firstMatch.tap()
      } else {
        app.tap()
      }

      if SystemLocationAlert.dismissIfPresent(app: app, preferDeny: true) {
        permissionPromptObserved = true
      }

      let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
      if !springboard.alerts.firstMatch.exists {
        break
      }
    }
  }
}
