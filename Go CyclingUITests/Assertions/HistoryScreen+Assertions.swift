//
//  HistoryScreen+Assertions.swift
//  Go CyclingUITests
//

import XCTest

extension HistoryScreen {
  func assertRideCount(
    _ expectedCount: Int,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    if expectedCount == 0 {
      ElementAssertions.assertExists(
        emptyState,
        timeout: Timeouts.short,
        file: file,
        line: line
      )
      return
    }
    ElementAssertions.assertExists(
      rideRow,
      timeout: Timeouts.standard,
      file: file,
      line: line
    )
    let rides = rideRows()
    XCTAssertEqual(
      rides.count,
      expectedCount,
      "Expected \(expectedCount) saved ride row(s) in History",
      file: file,
      line: line
    )
  }
}
