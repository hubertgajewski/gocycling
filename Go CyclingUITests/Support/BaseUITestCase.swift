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
}
