//
//  SettingsResetScreen.swift
//  Go CyclingUITests
//

import XCTest

/// Settings → Reset actions used to return the app to a clean local state.
final class SettingsResetScreen {
  private enum AlertLabel {
    static let delete = "Delete"
    static let reset = "Reset"
  }

  private let app: XCUIApplication

  init(app: XCUIApplication) {
    self.app = app
  }

  func performFullReset(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    confirmDestructiveAction(
      button: app.buttons[AccessibilityID.SettingsReset.deleteAllRoutesButton],
      alertButtonLabel: AlertLabel.delete,
      file: file,
      line: line
    )
    confirmDestructiveAction(
      button: app.buttons[AccessibilityID.SettingsReset.resetStatisticsButton],
      alertButtonLabel: AlertLabel.reset,
      file: file,
      line: line
    )
    confirmDestructiveAction(
      button: app.buttons[AccessibilityID.SettingsReset.resetDefaultSettingsButton],
      alertButtonLabel: AlertLabel.reset,
      file: file,
      line: line
    )
  }

  private func confirmDestructiveAction(
    button: XCUIElement,
    alertButtonLabel: String,
    file: StaticString,
    line: UInt
  ) {
    scrollUntilExists(button, file: file, line: line)
    button.tap()

    let alertButton = app.alerts.buttons[alertButtonLabel]
    Wait.assertExists(alertButton, file: file, line: line)
    alertButton.tap()
  }

  private func scrollUntilExists(
    _ element: XCUIElement,
    maxSwipes: Int = 12,
    file: StaticString,
    line: UInt
  ) {
    if element.waitForExistence(timeout: 1) {
      return
    }

    var swipes = 0
    while swipes < maxSwipes {
      app.swipeUp()
      swipes += 1
      if element.waitForExistence(timeout: 0.5) {
        return
      }
    }

    Wait.assertExists(element, file: file, line: line)
  }
}
