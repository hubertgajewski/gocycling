//
//  GoCyclingUITestCase.swift
//  Go CyclingUITests
//

import XCTest

/// Base class for launched-app UI tests.
///
/// Owns fail-fast behavior, app launch tracking, failure screenshots, and app
/// termination so individual tests can focus on their workflow assertions.
///
/// UI tests use the real simulator store (rides, defaults, review counters).
/// Call `resetAllStoredAppData` when a test needs a clean History or settings.
class GoCyclingUITestCase: XCTestCase {
  private let appLauncher = AppLauncher()
  private(set) var app: XCUIApplication?

  override func setUpWithError() throws {
    continueAfterFailure = false
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
    app = launchedApp
    return launchedApp
  }

  /// Settings → Reset cleanup so History and preferences start from a known state.
  func resetAllStoredAppData(
    app: XCUIApplication,
    mainTabs: MainTabBarScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    mainTabs.select(.settings)
    mainTabs.assertSelected(.settings, file: file, line: line)
    let reset = SettingsResetScreen(app: app)
    reset.deleteAllStoredRoutes(file: file, line: line)
    reset.resetToDefaultSettings(file: file, line: line)
    mainTabs.select(.cycle)
    mainTabs.assertSelected(.cycle, file: file, line: line)
  }
}
