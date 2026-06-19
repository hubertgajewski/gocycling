//
//  MainTabNavigationTests.swift
//  Go CyclingUITests
//

import XCTest

final class MainTabNavigationTests: GoCyclingUITestCase {
  func testMainTabBarNavigatesToAllTabs() throws {
    let app = launchApp()
    let mainTabs = MainTabBarScreen(app: app)

    XCTAssertTrue(mainTabs.waitForMainChrome(), "Expected Cycle tab chrome after launch")
    mainTabs.assertContentVisible(.cycle)
    Wait.assertExists(app.buttons[AccessibilityID.Cycle.startButton])

    mainTabs.select(.history)
    mainTabs.assertContentVisible(.history)

    mainTabs.select(.statistics)
    mainTabs.assertContentVisible(.statistics)

    mainTabs.select(.settings)
    mainTabs.assertContentVisible(.settings)
  }
}
