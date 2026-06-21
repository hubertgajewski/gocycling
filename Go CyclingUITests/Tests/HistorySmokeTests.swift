//
//  HistorySmokeTests.swift
//  Go CyclingUITests
//

import XCTest

/// Fast History tab smoke coverage for empty and populated ride-list states.
final class HistorySmokeTests: CycleUITestCase {
  func testHistoryTabShowsEmptyStateLabel() throws {
    mainTabs.select(.history)
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .history),
      timeout: Timeouts.standard
    )
    history.assertEmptyStateLabel()
  }

  func testSavedRideRowShowsHistoryMetricLabels() throws {
    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.completeStopAndSaveWithoutCategory(categorization: categorization)

    mainTabs.select(.history)
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .history),
      timeout: Timeouts.standard
    )
    history.assertRideCount(1)
    history.assertFirstRideRowMetricLabels()
  }
}
