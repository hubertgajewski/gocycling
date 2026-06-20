//
//  CycleRideRegressionTests.swift
//  Go CyclingUITests
//

import XCTest

/// Deep Cycle GUI and route categorization coverage.
final class CycleRideRegressionTests: CycleRideUITestCase {
  func testIdleCycleChromeShowsMapMetricsAndLockToggle() throws {
    CycleScreenAssertions.assertReadyToStart(on: cycle)
    CycleScreenAssertions.assertDefaultMetricsDisplayed(on: cycle)
    CycleScreenAssertions.assertMapLocked(on: cycle)
    cycle.unlockMap()
    CycleScreenAssertions.assertMapUnlocked(on: cycle)
    cycle.lockMap()
    CycleScreenAssertions.assertMapLocked(on: cycle)
  }

  func testPauseResumeAndCancelStopDoesNotSaveRide() throws {
    cycle.start()
    CycleScreenAssertions.assertLocationSettingsAlertPresented(on: cycle)
    cycle.dismissLocationSettingsAlertIfPresent()
    CycleScreenAssertions.assertRunning(on: cycle)
    cycle.pause()
    CycleScreenAssertions.assertPaused(on: cycle)
    cycle.resume()
    CycleScreenAssertions.assertRunning(on: cycle)
    cycle.requestStop()
    CycleScreenAssertions.assertStopConfirmationPresented(on: cycle)
    cycle.cancelStopConfirmation()
    CycleScreenAssertions.assertPausedAfterStopCancellation(on: cycle)

    mainTabs.select(.history)
    MainTabBarScreenAssertions.assertSelected(.history, on: mainTabs)
    HistoryScreenAssertions.assertEmpty(on: history)

    mainTabs.select(.cycle)
    MainTabBarScreenAssertions.assertSelected(.cycle, on: mainTabs)
    CycleScreenAssertions.assertPausedAfterStopCancellation(on: cycle)
  }

  func testCategorizeYourRouteLabelsVisible() throws {
    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    CycleScreenAssertions.assertRunning(on: cycle)
    cycle.completeStop()
    RouteCategorizationScreenAssertions.assertLabels(on: categorization)
    categorization.saveWithoutCategory()
  }

  func testSaveRideWithoutCategory() throws {
    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.completeStopAndSaveWithoutCategory(categorization: categorization)

    mainTabs.select(.history)
    HistoryScreenAssertions.assertRideCount(1, on: history)
  }

  func testSaveRideToNewCategory() throws {
    let categoryName = "Morning Ride"

    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.completeStop()
    RouteCategorizationScreenAssertions.assertPresented(on: categorization)
    categorization.saveNewCategory(named: categoryName)

    mainTabs.select(.history)
    HistoryScreenAssertions.assertRideCount(1, on: history)
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
    HistoryScreenAssertions.assertRideCount(2, on: history)
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
    CycleScreenAssertions.assertAutoPausedBanner(on: cycle)
    CycleScreenAssertions.assertPaused(on: cycle)
  }
}
