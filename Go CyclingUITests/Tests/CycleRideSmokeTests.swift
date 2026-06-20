//
//  CycleRideSmokeTests.swift
//  Go CyclingUITests
//

import XCTest

/// Fast Cycle happy path: start, pause/resume, stop, save to History.
final class CycleRideSmokeTests: CycleRideUITestCase {
  func testStartPauseResumeStopSavesRideToHistory() throws {
    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    CycleScreenAssertions.assertRunning(on: cycle)
    cycle.pause()
    CycleScreenAssertions.assertPaused(on: cycle)
    cycle.resume()
    CycleScreenAssertions.assertRunning(on: cycle)
    cycle.completeStopAndSaveWithoutCategory(categorization: categorization)

    mainTabs.select(.history)
    MainTabBarScreenAssertions.assertSelected(.history, on: mainTabs)
    HistoryScreenAssertions.assertHasRides(on: history)
  }
}
