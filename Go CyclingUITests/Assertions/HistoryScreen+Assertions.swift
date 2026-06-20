//
//  HistoryScreen+Assertions.swift
//  Go CyclingUITests
//

import XCTest

enum HistoryScreenAssertions {
  static func assertHasRides(
    on history: HistoryScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(
      history.rideRow,
      timeout: Timeouts.standard,
      file: file,
      line: line
    )
  }

  static func assertEmpty(
    on history: HistoryScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(
      history.emptyState,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
  }

  static func assertRideCount(
    _ expectedCount: Int,
    on history: HistoryScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let rides = history.rideRows()
    XCTAssertEqual(
      rides.count,
      expectedCount,
      "Expected \(expectedCount) saved ride row(s) in History",
      file: file,
      line: line
    )
  }
}
