//
//  MainTabNavigationTests.swift
//  Go CyclingUITests
//

import XCTest

/// Smoke coverage for root tab navigation only.
///
/// Detailed Cycle, History, Statistics, and Settings workflows belong in
/// focused tests and screen objects for those tabs.
final class MainTabNavigationTests: BaseTestCase {
  func testMainTabBarNavigatesToAllTabs() throws {
    let app = launchApp()
    let mainTabs = MainTabBarScreen(app: app)

    XCTAssertTrue(mainTabs.waitForMainChrome(), "Expected Cycle tab chrome after launch")
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .cycle),
      timeout: Timeouts.standard
    )
    ElementAssertions.assertExists(app.buttons[AccessibilityID.Cycle.startButton])

    mainTabs.select(.history)
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .history),
      timeout: Timeouts.standard
    )

    mainTabs.select(.statistics)
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .statistics),
      timeout: Timeouts.standard
    )

    mainTabs.select(.settings)
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .settings),
      timeout: Timeouts.standard
    )
  }
}
