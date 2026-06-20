//
//  AppLauncher.swift
//  Go CyclingUITests
//

import XCTest

/// Launch arguments understood by the app's DEBUG-only UI-testing seams.
enum LaunchArgument {
  static let uiTesting = "-ui-testing"
  static let cycleControlsFixture = "-ui-testing-cycle-controls-fixture"
  static let autoPauseFixture = "-ui-testing-auto-pause-fixture"
  static let appleLanguages = "-AppleLanguages"
  static let appleLocale = "-AppleLocale"
  static let applePersistenceIgnoreState = "-ApplePersistenceIgnoreState"
}

/// Creates consistently configured app instances for UI tests.
///
/// All UI tests should launch through this helper so test mode, English
/// fallback labels, and state-restoration isolation stay consistent across the
/// iPhone and iPad smoke matrix.
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
