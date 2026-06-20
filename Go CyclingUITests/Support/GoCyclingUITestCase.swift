//
//  GoCyclingUITestCase.swift
//  Go CyclingUITests
//

import XCTest

/// Base class for launched-app UI tests.
///
/// Owns fail-fast behavior, app launch tracking, failure screenshots, and app
/// termination so individual tests can focus on their workflow assertions.
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

  /// Settings → Reset cleanup so History and statistics start from a known empty state.
  func resetAllStoredAppData(
    app: XCUIApplication,
    mainTabs: MainTabBarScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    mainTabs.select(.settings)
    mainTabs.assertSelected(.settings, file: file, line: line)
    SettingsResetScreen(app: app).performFullReset(file: file, line: line)
    mainTabs.select(.cycle)
    mainTabs.assertSelected(.cycle, file: file, line: line)
  }
}
