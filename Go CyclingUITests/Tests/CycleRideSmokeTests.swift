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
    cycle.assertRunning()
    cycle.pause()
    cycle.assertPaused()
    cycle.resume()
    cycle.assertRunning()
    cycle.completeStopAndSaveWithoutCategory(categorization: categorization)

    mainTabs.select(.history)
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .history),
      timeout: Timeouts.standard
    )
    history.assertRideCount(1)
  }
}
