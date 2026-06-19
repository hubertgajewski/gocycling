//
//  AppLauncher.swift
//  Go CyclingUITests
//

import XCTest

enum LaunchArgument {
  static let uiTesting = "-ui-testing"
  static let routeSaveFixture = "-ui-testing-route-save-fixture"
  static let cycleControlsFixture = "-ui-testing-cycle-controls-fixture"
  static let appleLanguages = "-AppleLanguages"
  static let appleLocale = "-AppleLocale"
  static let applePersistenceIgnoreState = "-ApplePersistenceIgnoreState"
}

struct AppLauncher {
  private let baseArguments = [
    LaunchArgument.uiTesting,
    LaunchArgument.appleLanguages, "(en)",
    LaunchArgument.appleLocale, "en_US",
    LaunchArgument.applePersistenceIgnoreState, "YES",
  ]

  func launch(
    extraArguments: [String] = [],
    environment: [String: String] = [:]
  ) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = baseArguments + extraArguments
    app.launchEnvironment = environment
    app.launch()
    return app
  }
}
