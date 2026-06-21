//
//  CycleRideRegressionTests.swift
//  Go CyclingUITests
//

import XCTest

/// Deep Cycle GUI and route categorization coverage.
final class CycleRideRegressionTests: CycleUITestCase {
  func testIdleCycleChromeShowsMapMetricsAndLockToggle() throws {
    cycle.assertReadyToStart()
    cycle.assertDefaultMetricsDisplayed()
    ElementAssertions.assertExists(cycle.mapLockButton)
    cycle.unlockMap()
    ElementAssertions.assertExists(cycle.mapUnlockButton)
    cycle.lockMap()
    ElementAssertions.assertExists(cycle.mapLockButton)
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
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .history),
      timeout: Timeouts.standard
    )
    ElementAssertions.assertExists(history.emptyState, timeout: Timeouts.short)

    mainTabs.select(.cycle)
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .cycle),
      timeout: Timeouts.standard
    )
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
final class CycleAutoPauseRegressionTests: CycleUITestCase {
  override var launchExtraArguments: [String] {
    [
      LaunchArgument.cycleControlsFixture,
      LaunchArgument.autoPauseFixture,
    ]
  }

  func testAutoPausedBannerAppearsWhenStopped() throws {
    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.assertAutoPaused()
  }
}
