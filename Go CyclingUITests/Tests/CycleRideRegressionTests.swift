//
//  CycleRideRegressionTests.swift
//  Go CyclingUITests
//

import XCTest

/// Deep Cycle GUI and route categorization coverage.
final class CycleRideRegressionTests: CycleRideUITestCase {
  func testIdleCycleChromeShowsMapMetricsAndLockToggle() throws {
    cycle.assertReadyToStart()
    cycle.assertDefaultMetricsDisplayed()
    cycle.assertMapLocked()
    cycle.unlockMap()
    cycle.assertMapUnlocked()
    cycle.lockMap()
    cycle.assertMapLocked()
  }

  func testPauseResumeAndCancelStopDoesNotSaveRide() throws {
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
    cycle.assertPaused()

    mainTabs.select(.history)
    mainTabs.assertSelected(.history)
    history.assertEmpty()

    mainTabs.select(.cycle)
    mainTabs.assertSelected(.cycle)
    cycle.assertPaused()
  }

  func testCategorizeYourRouteLabelsVisible() throws {
    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.assertRunning()
    cycle.completeStop()
    categorization.assertLabels()
    categorization.saveWithoutCategory()
  }

  func testSaveRideWithoutCategory() throws {
    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.completeStopAndSaveWithoutCategory(categorization: categorization)

    mainTabs.select(.history)
    history.assertRideCount(1)
  }

  func testSaveRideToNewCategory() throws {
    let categoryName = "Morning Ride"

    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.completeStop()
    categorization.assertPresented()
    categorization.saveNewCategory(named: categoryName)

    mainTabs.select(.history)
    history.assertRideCount(1)
  }

  func testSaveRideToExistingCategory() throws {
    let categoryName = "Commute"

    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.completeStop()
    categorization.saveNewCategory(named: categoryName)

    mainTabs.select(.cycle)
    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.completeStop()
    categorization.selectExistingCategory(named: categoryName, at: 0)

    mainTabs.select(.history)
    history.assertRideCount(2)
  }
}

/// Auto-pause needs an extra launch fixture; separate class keeps launch config explicit.
final class CycleAutoPauseRegressionTests: CycleRideUITestCase {
  override var launchExtraArguments: [String] {
    [
      LaunchArgument.cycleControlsFixture,
      LaunchArgument.autoPauseFixture,
    ]
  }

  func testAutoPausedBannerAppearsWhenStopped() throws {
    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.assertAutoPausedBanner()
    cycle.assertPaused()
  }
}
