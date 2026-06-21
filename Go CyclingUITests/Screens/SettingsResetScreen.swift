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

  func deleteAllStoredRoutes(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    confirmDestructiveAction(
      button: app.buttons[AccessibilityID.Settings.deleteAllRoutesButton],
      alertButtonLabel: AlertLabel.delete,
      file: file,
      line: line
    )
  }

  func resetStoredStatistics(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    confirmDestructiveAction(
      button: app.buttons[AccessibilityID.Settings.resetStatisticsButton],
      alertButtonLabel: AlertLabel.reset,
      file: file,
      line: line
    )
  }

  func resetToDefaultSettings(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    confirmDestructiveAction(
      button: app.buttons[AccessibilityID.Settings.resetDefaultSettingsButton],
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
    ElementAssertions.assertExists(alertButton, file: file, line: line)
    alertButton.tap()
  }

  private func scrollUntilExists(
    _ element: XCUIElement,
    maxSwipes: Int = 12,
    file: StaticString,
    line: UInt
  ) {
    if element.waitForExistence(timeout: Timeouts.brief) {
      return
    }

    for _ in 0..<maxSwipes {
      if element.waitForExistence(timeout: Timeouts.poll) {
        return
      }
      app.swipeUp()
    }

    for _ in 0..<maxSwipes {
      if element.waitForExistence(timeout: Timeouts.poll) {
        return
      }
      app.swipeDown()
    }

    ElementAssertions.assertExists(element, file: file, line: line)
  }
}
