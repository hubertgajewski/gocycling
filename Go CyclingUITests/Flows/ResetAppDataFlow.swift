//
//  ResetAppDataFlow.swift
//  Go CyclingUITests
//

import XCTest

/// Settings → Reset cleanup so UI tests start from a known local store.
struct ResetAppDataFlow {
  struct Areas: OptionSet {
    let rawValue: UInt

    static let routes = Areas(rawValue: 1 << 0)
    static let statistics = Areas(rawValue: 1 << 1)
    static let settings = Areas(rawValue: 1 << 2)

    static let all: Areas = [.routes, .statistics, .settings]
    static let cycleDefaults: Areas = [.routes, .settings]
    static let statisticsSmoke: Areas = [.routes, .statistics, .settings]
    static let settingsOnly: Areas = [.settings]
  }

  let app: XCUIApplication
  let tabs: MainTabBarScreen

  func run(
    resetting areas: Areas = .cycleDefaults,
    returnTo tab: MainTabBarScreen.Tab = .cycle,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    guard !areas.isEmpty else {
      return
    }

    tabs.select(.settings, file: file, line: line)
    waitForTabContent(.settings, file: file, line: line)

    let reset = SettingsResetScreen(app: app)
    if areas.contains(.routes) {
      reset.deleteAllStoredRoutes(file: file, line: line)
    }
    if areas.contains(.statistics) {
      reset.resetStoredStatistics(file: file, line: line)
    }
    if areas.contains(.settings) {
      reset.resetToDefaultSettings(file: file, line: line)
    }

    tabs.select(tab, file: file, line: line)
    waitForTabContent(tab, file: file, line: line)
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
