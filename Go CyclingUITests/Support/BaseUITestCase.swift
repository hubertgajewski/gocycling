//
//  BaseUITestCase.swift
//  Go CyclingUITests
//

import XCTest

/// Base class for launched-app UI tests.
///
/// Owns fail-fast behavior, app launch tracking, failure screenshots, and app
/// termination so individual tests can focus on their workflow assertions.
class BaseUITestCase: XCTestCase {
  private let appLauncher = AppLauncher()
  private(set) var app: XCUIApplication?

  override func setUpWithError() throws {
    continueAfterFailure = false

    // Host-side simctl grant can still leave a system sheet on first launch; XCTest's
    // default interruption handler taps "Don't Allow", which blocks route save.
    addUIInterruptionMonitor(withDescription: "Allow system location for UI tests") { alert in
      guard SystemLocationAlert.isLocationPermissionAlert(alert) else { return false }
      return SystemLocationAlert.dismiss(alert: alert, preferDeny: false)
    }
  }

  override func tearDownWithError() throws {
    if let app {
      if let testRun, testRun.failureCount > 0 {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "\(name)-failure"
        attachment.lifetime = .keepAlways
        add(attachment)
      }

      app.terminate()
    }

    app = nil
  }

  @discardableResult
  func launchApp(
    extraArguments: [String] = [],
    environment: [String: String] = [:]
  ) -> XCUIApplication {
    let launchedApp = appLauncher.launch(
      extraArguments: extraArguments,
      environment: environment
    )
    SystemLocationAlert.triggerInterruptionMonitor(on: launchedApp, preferDeny: false)
    app = launchedApp
    return launchedApp
  }
}
