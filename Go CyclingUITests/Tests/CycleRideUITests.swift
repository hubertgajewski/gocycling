//
//  CycleRideUITests.swift
//  Go CyclingUITests
//

import XCTest

/// End-to-end Cycle ride session: map lock toggle, start, pause/resume, stop/cancel, no save.
final class CycleRideUITests: GoCyclingUITestCase {
  func testPauseResumeAndCancelStopDoesNotSaveRide() throws {
    let app = launchApp(extraArguments: [LaunchArgument.cycleControlsFixture])
    let mainTabs = MainTabBarScreen(app: app)
    let cycle = CycleScreen(app: app)

    XCTAssertTrue(mainTabs.waitForMainChrome(), "Expected Cycle tab chrome after launch")
    mainTabs.assertSelected(.cycle)
    resetAllStoredAppData(app: app, mainTabs: mainTabs)

    cycle.assertReadyToStart()
    cycle.assertMapLocked()
    cycle.unlockMap()
    cycle.assertMapUnlocked()
    cycle.lockMap()
    cycle.assertMapLocked()

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
    Wait.assertExists(
      app.staticTexts[AccessibilityID.History.emptyState],
      timeout: Wait.Timeout.short,
      "Canceling stop confirmation should not save a ride"
    )

    mainTabs.select(.cycle)
    mainTabs.assertSelected(.cycle)
    cycle.assertPausedAfterStopCancellation()
  }
}
