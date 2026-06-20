//
//  ResetAppDataFlow.swift
//  Go CyclingUITests
//

import XCTest

/// Settings → Reset cleanup so Cycle ride tests start from a known local store.
struct ResetAppDataFlow {
  let app: XCUIApplication
  let tabs: MainTabBarScreen

  func run(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    tabs.select(.settings, file: file, line: line)
    MainTabBarScreenAssertions.assertSelected(.settings, on: tabs, file: file, line: line)

    let reset = SettingsResetScreen(app: app)
    reset.deleteAllStoredRoutes(file: file, line: line)
    reset.resetToDefaultSettings(file: file, line: line)

    tabs.select(.cycle, file: file, line: line)
    MainTabBarScreenAssertions.assertSelected(.cycle, on: tabs, file: file, line: line)
  }
}
