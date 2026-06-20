//
//  MainTabNavigationTests.swift
//  Go CyclingUITests
//

import XCTest

/// Smoke coverage for root tab navigation only.
///
/// Detailed Cycle, History, Statistics, and Settings workflows belong in
/// focused tests and screen objects for those tabs.
final class MainTabNavigationTests: GoCyclingUITestCase {
  func testMainTabBarNavigatesToAllTabs() throws {
    let app = launchApp()
    let mainTabs = MainTabBarScreen(app: app)

    XCTAssertTrue(mainTabs.waitForMainChrome(), "Expected Cycle tab chrome after launch")
    MainTabBarScreenAssertions.assertSelected(.cycle, on: mainTabs)
    ElementAssertions.assertExists(app.buttons[AccessibilityID.Cycle.startButton])

    mainTabs.select(.history)
    MainTabBarScreenAssertions.assertSelected(.history, on: mainTabs)

    mainTabs.select(.statistics)
    MainTabBarScreenAssertions.assertSelected(.statistics, on: mainTabs)

    mainTabs.select(.settings)
    MainTabBarScreenAssertions.assertSelected(.settings, on: mainTabs)
  }
}
