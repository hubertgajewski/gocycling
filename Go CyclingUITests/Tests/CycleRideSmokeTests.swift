//
//  CycleRideSmokeTests.swift
//  Go CyclingUITests
//

import XCTest

/// Fast Cycle happy path: start, pause/resume, stop, save, return to idle Cycle chrome.
final class CycleRideSmokeTests: CycleUITestCase {
  func testStartPauseResumeStopSavesRideOnCycleTab() throws {
    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.assertRunning()
    cycle.pause()
    cycle.assertPaused()
    cycle.resume()
    cycle.assertRunning()
    cycle.completeStopAndSaveWithoutCategory(categorization: categorization)
  }
}
