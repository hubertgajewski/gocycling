//
//  GoCyclingUITests.swift
//  Go CyclingUITests
//
//  Created by Anthony Hopkins on 2021-03-14.
//

import XCTest

/// Existing fixture-backed UI smoke coverage.
///
/// This file keeps the pre-harness Cycle and route-save scenarios passing while
/// newer UI tests move into focused files under `Go CyclingUITests/Tests`.
final class GoCyclingUITests: GoCyclingUITestCase {
  func testRouteSaveFixtureCreatesHistoryRide() throws {
    let app = launchApp(extraArguments: [LaunchArgument.routeSaveFixture])
    let mainTabs = MainTabBarScreen(app: app)

    XCTAssertTrue(mainTabs.waitForMainChrome(), "Expected Cycle tab chrome after launch")

    mainTabs.select(.history)
    mainTabs.assertSelected(.history)
    Wait.assertExists(app.staticTexts["Distance Cycled"], timeout: Wait.Timeout.fixture)

    mainTabs.select(.cycle)
    mainTabs.assertSelected(.cycle)
  }

  func testCycleControlsExposeStableAccessibilityIdentifiers() throws {
    let app = launchApp(extraArguments: [LaunchArgument.cycleControlsFixture])
    let mainTabs = MainTabBarScreen(app: app)
    let cycle = CycleScreen(app: app)

    XCTAssertTrue(mainTabs.waitForMainChrome(), "Expected Cycle tab chrome after launch")
    mainTabs.assertSelected(.cycle)

    cycle.assertReadyToStart()
    cycle.assertMapLocked()

    cycle.lockMap()
    cycle.assertMapUnlocked()

    cycle.start()
    cycle.assertLocationSettingsAlertPresented()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.assertRunning()

    cycle.pause()
    cycle.assertPaused()

    cycle.requestStop()
    cycle.assertStopConfirmationPresented()
    cycle.cancelStopConfirmation()
    cycle.assertPausedAfterStopCancellation()
  }
}
