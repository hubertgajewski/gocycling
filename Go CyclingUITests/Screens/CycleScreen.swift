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
    static let locationSettingsTitle = "Location settings may not be correct"
  }

  private let app: XCUIApplication

  init(app: XCUIApplication) {
    self.app = app
  }

  func assertReadyToStart(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(timerDisplay, file: file, line: line)
    Wait.assertExists(startButton, file: file, line: line)
    Wait.assertExists(metricsPill, file: file, line: line)
    // MKMapView accessibility identifiers are not reliably exposed to XCUITest;
    // the map lock control sits on the map overlay and proves map chrome loaded.
    Wait.assertExists(mapLockButton, file: file, line: line)
  }

  func assertDefaultMetricsDisplayed(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(metricsSpeedValue, file: file, line: line)
    Wait.assertExists(metricsDistanceValue, file: file, line: line)
    Wait.assertExists(metricsAltitudeValue, file: file, line: line)
    XCTAssertEqual(metricsSpeedValue.label, "0.0", file: file, line: line)
    XCTAssertEqual(metricsDistanceValue.label, "0.0", file: file, line: line)
    XCTAssertEqual(metricsAltitudeValue.label, "0.0", file: file, line: line)
    XCTAssertTrue(
      app.staticTexts["km/h"].exists || app.staticTexts["mph"].exists,
      "Expected speed units to be visible in the metrics pill",
      file: file,
      line: line
    )
  }

  func assertMapLocked(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(mapLockButton, file: file, line: line)
  }

  func assertMapUnlocked(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(mapUnlockButton, file: file, line: line)
  }

  func unlockMap(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(mapLockButton, file: file, line: line)
    mapLockButton.tap()
  }

  func lockMap(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(mapUnlockButton, file: file, line: line)
    mapUnlockButton.tap()
  }

  func start(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(startButton, file: file, line: line)
    startButton.tap()
  }

  func assertLocationSettingsAlertPresented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(
      app.alerts[AlertLabel.locationSettingsTitle],
      timeout: Wait.Timeout.short,
      "Expected the location settings alert title",
      file: file,
      line: line
    )
    XCTAssertNotNil(
      locationSettingsOpenSettingsButton(),
      "Expected the app-owned location settings alert Open Settings action",
      file: file,
      line: line
    )
    XCTAssertNotNil(
      locationSettingsIgnoreButton(),
      "Expected the app-owned location settings alert Ignore action",
      file: file,
      line: line
    )
  }

  func dismissLocationSettingsAlertIfPresent() {
    locationSettingsIgnoreButton()?.tap()
  }

  func assertRunning(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(pauseButton, timeout: Wait.Timeout.short, file: file, line: line)
    Wait.assertExists(stopButton, file: file, line: line)
  }

  func pause(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(pauseButton, timeout: Wait.Timeout.short, file: file, line: line)
    pauseButton.tap()
  }

  func assertPaused(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(resumeButton, file: file, line: line)
    Wait.assertExists(stopButton, file: file, line: line)
  }

  func resume(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(resumeButton, file: file, line: line)
    resumeButton.tap()
  }

  func requestStop(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(stopButton, file: file, line: line)
    stopButton.tap()
  }

  func assertStopConfirmationPresented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertNotNil(
      stopConfirmationStopButton(),
      "Expected the app-owned stop confirmation Stop action",
      file: file,
      line: line
    )
    XCTAssertNotNil(
      stopConfirmationCancelButton(),
      "Expected the app-owned stop confirmation Cancel action",
      file: file,
      line: line
    )
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

  func assertAutoPausedBanner(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(autoPausedBanner, timeout: Wait.Timeout.standard, file: file, line: line)
  }

  func completeStop(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    requestStop(file: file, line: line)
    assertStopConfirmationPresented(file: file, line: line)
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

  func assertPausedAfterStopCancellation(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertPaused(file: file, line: line)
  }

  private var timerDisplay: XCUIElement {
    app.staticTexts[AccessibilityID.Cycle.timerDisplay]
  }

  private var metricsPill: XCUIElement {
    identifiedElement(AccessibilityID.Cycle.metricsPill)
  }

  private var metricsSpeedValue: XCUIElement {
    identifiedElement(AccessibilityID.Cycle.metricsSpeedValue)
  }

  private var metricsDistanceValue: XCUIElement {
    identifiedElement(AccessibilityID.Cycle.metricsDistanceValue)
  }

  private var metricsAltitudeValue: XCUIElement {
    identifiedElement(AccessibilityID.Cycle.metricsAltitudeValue)
  }

  private var autoPausedBanner: XCUIElement {
    identifiedElement(AccessibilityID.Cycle.autoPausedBanner)
  }

  private var mapLockButton: XCUIElement {
    app.buttons[AccessibilityID.Cycle.mapLockButton]
  }

  private var mapUnlockButton: XCUIElement {
    app.buttons[AccessibilityID.Cycle.mapUnlockButton]
  }

  private var startButton: XCUIElement {
    app.buttons[AccessibilityID.Cycle.startButton]
  }

  private var pauseButton: XCUIElement {
    app.buttons[AccessibilityID.Cycle.pauseButton]
  }

  private var resumeButton: XCUIElement {
    app.buttons[AccessibilityID.Cycle.resumeButton]
  }

  private var stopButton: XCUIElement {
    app.buttons[AccessibilityID.Cycle.stopButton]
  }

  private func locationSettingsOpenSettingsButton() -> XCUIElement? {
    alertButton(
      identifier: AccessibilityID.Cycle.locationSettingsOpenSettingsButton,
      label: AlertLabel.openSettings
    )
  }

  private func locationSettingsIgnoreButton() -> XCUIElement? {
    alertButton(
      identifier: AccessibilityID.Cycle.locationSettingsIgnoreButton,
      label: AlertLabel.ignore
    )
  }

  private func stopConfirmationStopButton() -> XCUIElement? {
    alertButton(
      identifier: AccessibilityID.Cycle.stopConfirmationStopButton,
      label: AlertLabel.stop
    )
  }

  private func stopConfirmationCancelButton() -> XCUIElement? {
    alertButton(
      identifier: AccessibilityID.Cycle.stopConfirmationCancelButton,
      label: AlertLabel.cancel
    )
  }

  private func alertButton(
    identifier: String,
    label: String,
    timeout: TimeInterval = Wait.Timeout.short
  ) -> XCUIElement? {
    if #available(iOS 15.0, *) {
      let identifiedButton = app.buttons.matching(identifier: identifier).firstMatch
      if Wait.exists(identifiedButton, timeout: timeout) {
        return identifiedButton
      }
    }

    let labeledButton = app.buttons[label].firstMatch
    return Wait.exists(labeledButton, timeout: timeout) ? labeledButton : nil
  }

  private func identifiedElement(_ identifier: String) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: identifier).firstMatch
  }
}
