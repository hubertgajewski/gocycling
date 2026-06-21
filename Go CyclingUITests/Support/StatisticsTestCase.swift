//
//  StatisticsTestCase.swift
//  Go CyclingUITests
//

import XCTest

/// Shared launch + Settings reset for Statistics tab UI tests.
///
/// Clears stored routes and statistics so chart/record labels reflect a known
/// baseline while awards remain locked in UI tests.
class StatisticsTestCase: CycleTestCase {
  private(set) var statistics: StatisticsScreen!

  override var resetAreas: ResetAppDataFlow.Areas {
    .statisticsSmoke
  }

  override func setUpWithError() throws {
    try super.setUpWithError()
    statistics = StatisticsScreen(app: try XCTUnwrap(app))
  }
}
