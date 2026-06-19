//
//  CycleTimerStopCancelTests.swift
//  Go CyclingUITests
//

import XCTest

/// Focused Cycle timer coverage that does not save a route.
final class CycleTimerStopCancelTests: GoCyclingUITestCase {
  func testCycleTimerStopsAndCancelsWithoutSavingRide() throws {
    let app = launchApp(extraArguments: [LaunchArgument.cycleControlsFixture])
    let mainTabs = MainTabBarScreen(app: app)
    let cycle = CycleScreen(app: app)

    XCTAssertTrue(mainTabs.waitForMainChrome(), "Expected Cycle tab chrome after launch")
    mainTabs.assertSelected(.cycle)

    cycle.assertReadyToStart()
    cycle.start()
    cycle.assertLocationSettingsAlertPresented()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.assertRunning()

    cycle.pause()
    cycle.assertPaused()

    cycle.resume()
    cycle.assertRunning()

    cycle.requestStop()
    cycle.assertStopConfirmationPresented()
    cycle.cancelStopConfirmation()
    cycle.assertPausedAfterStopCancellation()

    mainTabs.select(.history)
    mainTabs.assertSelected(.history)
    XCTAssertFalse(
      app.staticTexts["Distance Cycled"].waitForExistence(timeout: 1),
      "Canceling stop confirmation should not save a ride"
    )

    mainTabs.select(.cycle)
    mainTabs.assertSelected(.cycle)
    cycle.assertPausedAfterStopCancellation()
  }
}
