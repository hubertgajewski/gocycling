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
    ElementAssertions.assertExists(cycle.pauseButton, timeout: Timeouts.short)
    ElementAssertions.assertExists(cycle.stopButton)
    cycle.pause()
    ElementAssertions.assertExists(cycle.resumeButton)
    ElementAssertions.assertExists(cycle.stopButton)
    cycle.resume()
    ElementAssertions.assertExists(cycle.pauseButton, timeout: Timeouts.short)
    ElementAssertions.assertExists(cycle.stopButton)
    cycle.completeStopAndSaveWithoutCategory(categorization: categorization)

    mainTabs.select(.history)
    ElementAssertions.assertExists(mainTabs.tabContent(for: .history), timeout: Timeouts.standard)
    history.assertRideCount(1)
  }
}
