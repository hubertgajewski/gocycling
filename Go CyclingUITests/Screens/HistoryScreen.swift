//
//  HistoryScreen.swift
//  Go CyclingUITests
//

import XCTest

/// Screen object for History tab ride list assertions.
final class HistoryScreen {
  private let app: XCUIApplication

  init(app: XCUIApplication) {
    self.app = app
  }

  func assertHasRides(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(
      rideRow,
      timeout: Wait.Timeout.standard,
      file: file,
      line: line
    )
  }

  func assertEmpty(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(
      emptyState,
      timeout: Wait.Timeout.short,
      file: file,
      line: line
    )
  }

  func assertRideCount(
    _ expectedCount: Int,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let rides = rideRows()
    XCTAssertEqual(
      rides.count,
      expectedCount,
      "Expected \(expectedCount) saved ride row(s) in History",
      file: file,
      line: line
    )
  }

  private func rideRows() -> XCUIElementQuery {
    let cells = app.cells.matching(identifier: AccessibilityID.History.rideRow)
    if cells.count > 0 {
      return cells
    }
    return app.descendants(matching: .any)
      .matching(identifier: AccessibilityID.History.rideRow)
  }

  private var rideRow: XCUIElement {
    rideRows().firstMatch
  }

  private var emptyState: XCUIElement {
    app.descendants(matching: .any)
      .matching(identifier: AccessibilityID.History.emptyState)
      .firstMatch
  }
}
