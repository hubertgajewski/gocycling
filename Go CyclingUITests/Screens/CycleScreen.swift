//
//  CycleScreen.swift
//  Go CyclingUITests
//

import XCTest

/// Screen object for Cycle tab controls and app-owned Cycle alerts.
final class CycleScreen {
  private enum AlertLabel {
    static let openSettings = "Open Settings"
    static let ignore = "Ignore"
    static let stop = "Stop"
    static let cancel = "Cancel"
  }

  let application: XCUIApplication

  init(app: XCUIApplication) {
    self.application = app
  }

  func unlockMap(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(mapLockButton, file: file, line: line)
    mapLockButton.tap()
  }

  func lockMap(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(mapUnlockButton, file: file, line: line)
    mapUnlockButton.tap()
  }

  func start(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(startButton, file: file, line: line)
    startButton.tap()
  }

  func dismissLocationSettingsAlertIfPresent() {
    locationSettingsIgnoreButton()?.tap()
  }

  func pause(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(pauseButton, timeout: Timeouts.short, file: file, line: line)
    pauseButton.tap()
  }

  func resume(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(resumeButton, file: file, line: line)
    resumeButton.tap()
  }

  func requestStop(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(stopButton, file: file, line: line)
    stopButton.tap()
  }

  func cancelStopConfirmation(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    guard let cancelButton = stopConfirmationCancelButton() else {
      XCTFail("Expected the app-owned stop confirmation Cancel action", file: file, line: line)
      return
    }

    cancelButton.tap()
  }

  func confirmStop(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    guard let stopButton = stopConfirmationStopButton() else {
      XCTFail("Expected the app-owned stop confirmation Stop action", file: file, line: line)
      return
    }

    stopButton.tap()
  }

  func completeStop(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    requestStop(file: file, line: line)
    CycleScreenAssertions.assertStopConfirmationPresented(on: self, file: file, line: line)
    confirmStop(file: file, line: line)
  }

  func completeStopAndSaveWithoutCategory(
    categorization: RouteCategorizationScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    completeStop(file: file, line: line)
    categorization.saveWithoutCategory(file: file, line: line)
  }

  // MARK: - Internal queries for Assertions

  var timerDisplay: XCUIElement {
    application.staticTexts[AccessibilityID.Cycle.timerDisplay]
  }

  var metricsPill: XCUIElement {
    identifiedElement(AccessibilityID.Cycle.metricsPill)
  }

  var metricsSpeedValue: XCUIElement {
    identifiedElement(AccessibilityID.Cycle.metricsSpeedValue)
  }

  var metricsDistanceValue: XCUIElement {
    identifiedElement(AccessibilityID.Cycle.metricsDistanceValue)
  }

  var metricsAltitudeValue: XCUIElement {
    identifiedElement(AccessibilityID.Cycle.metricsAltitudeValue)
  }

  var autoPausedBanner: XCUIElement {
    identifiedElement(AccessibilityID.Cycle.autoPausedBanner)
  }

  var mapLockButton: XCUIElement {
    application.buttons[AccessibilityID.Cycle.mapLockButton]
  }

  var mapUnlockButton: XCUIElement {
    application.buttons[AccessibilityID.Cycle.mapUnlockButton]
  }

  var startButton: XCUIElement {
    application.buttons[AccessibilityID.Cycle.startButton]
  }

  var pauseButton: XCUIElement {
    application.buttons[AccessibilityID.Cycle.pauseButton]
  }

  var resumeButton: XCUIElement {
    application.buttons[AccessibilityID.Cycle.resumeButton]
  }

  var stopButton: XCUIElement {
    application.buttons[AccessibilityID.Cycle.stopButton]
  }

  func locationSettingsOpenSettingsButton() -> XCUIElement? {
    alertButton(
      identifier: AccessibilityID.Cycle.locationSettingsOpenSettingsButton,
      label: AlertLabel.openSettings
    )
  }

  func locationSettingsIgnoreButton() -> XCUIElement? {
    alertButton(
      identifier: AccessibilityID.Cycle.locationSettingsIgnoreButton,
      label: AlertLabel.ignore
    )
  }

  func stopConfirmationStopButton() -> XCUIElement? {
    alertButton(
      identifier: AccessibilityID.Cycle.stopConfirmationStopButton,
      label: AlertLabel.stop
    )
  }

  func stopConfirmationCancelButton() -> XCUIElement? {
    alertButton(
      identifier: AccessibilityID.Cycle.stopConfirmationCancelButton,
      label: AlertLabel.cancel
    )
  }

  private func alertButton(
    identifier: String,
    label: String,
    timeout: TimeInterval = Timeouts.short
  ) -> XCUIElement? {
    if #available(iOS 15.0, *) {
      let identifiedButton = application.buttons.matching(identifier: identifier).firstMatch
      if identifiedButton.waitForExistence(timeout: timeout) {
        return identifiedButton
      }
    }

    let labeledButton = application.buttons[label].firstMatch
    return labeledButton.waitForExistence(timeout: timeout) ? labeledButton : nil
  }

  private func identifiedElement(_ identifier: String) -> XCUIElement {
    application.descendants(matching: .any).matching(identifier: identifier).firstMatch
  }
}
