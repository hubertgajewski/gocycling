//
//  HistoryScreen.swift
//  Go CyclingUITests
//

import XCTest

/// Screen object for History tab ride list queries.
final class HistoryScreen {
  let application: XCUIApplication

  init(app: XCUIApplication) {
    self.application = app
  }

  func rideRows() -> XCUIElementQuery {
    let cells = application.cells.matching(identifier: AccessibilityID.History.rideRow)
    if cells.count > 0 {
      return cells
    }
    return application.descendants(matching: .any)
      .matching(identifier: AccessibilityID.History.rideRow)
  }

  var rideRow: XCUIElement {
    rideRows().firstMatch
  }

  var emptyState: XCUIElement {
    application.descendants(matching: .any)
      .matching(identifier: AccessibilityID.History.emptyState)
      .firstMatch
  }
}
