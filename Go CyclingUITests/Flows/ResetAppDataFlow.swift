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
    waitForTabContent(.settings, file: file, line: line)

    let reset = SettingsResetScreen(app: app)
    reset.deleteAllStoredRoutes(file: file, line: line)
    reset.resetToDefaultSettings(file: file, line: line)

    tabs.select(.cycle, file: file, line: line)
    waitForTabContent(.cycle, file: file, line: line)
  }

  private func waitForTabContent(
    _ tab: MainTabBarScreen.Tab,
    file: StaticString,
    line: UInt
  ) {
    XCTAssertTrue(
      tabs.tabContent(for: tab).waitForExistence(timeout: Timeouts.standard),
      "Expected \(tab) tab content after navigation",
      file: file,
      line: line
    )
  }
}
