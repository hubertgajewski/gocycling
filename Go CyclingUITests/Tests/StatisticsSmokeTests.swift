//
//  StatisticsSmokeTests.swift
//  Go CyclingUITests
//

import XCTest

/// Fast Statistics tab smoke coverage after a saved ride updates charts and records.
final class StatisticsSmokeTests: StatisticsUITestCase {
  func testSavedRideStatisticsTabShowsSectionLabels() throws {
    cycle.start()
    cycle.dismissLocationSettingsAlertIfPresent()
    cycle.completeStopAndSaveWithoutCategory(categorization: categorization)

    mainTabs.select(.statistics)
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .statistics),
      timeout: Timeouts.standard
    )
    statistics.assertSavedRideStatisticsLabels()
  }
}
