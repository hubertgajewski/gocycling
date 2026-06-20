//
//  CycleScreen+Assertions.swift
//  Go CyclingUITests
//

import XCTest

enum CycleScreenAssertions {
  private enum AlertLabel {
    static let locationSettingsTitle = "Location settings may not be correct"
  }

  static func assertReadyToStart(
    on cycle: CycleScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(cycle.timerDisplay, file: file, line: line)
    ElementAssertions.assertExists(cycle.startButton, file: file, line: line)
    ElementAssertions.assertExists(cycle.metricsPill, file: file, line: line)
    // MKMapView accessibility identifiers are not reliably exposed to XCUITest;
    // the map lock control sits on the map overlay and proves map chrome loaded.
    ElementAssertions.assertExists(cycle.mapLockButton, file: file, line: line)
  }

  static func assertDefaultMetricsDisplayed(
    on cycle: CycleScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(cycle.metricsSpeedValue, file: file, line: line)
    ElementAssertions.assertExists(cycle.metricsDistanceValue, file: file, line: line)
    ElementAssertions.assertExists(cycle.metricsAltitudeValue, file: file, line: line)
    ElementAssertions.assertLabel(cycle.metricsSpeedValue, equals: "0.0", file: file, line: line)
    ElementAssertions.assertLabel(cycle.metricsDistanceValue, equals: "0.0", file: file, line: line)
    ElementAssertions.assertLabel(cycle.metricsAltitudeValue, equals: "0.0", file: file, line: line)
    XCTAssertTrue(
      cycle.application.staticTexts["km/h"].exists || cycle.application.staticTexts["mph"].exists,
      "Expected speed units to be visible in the metrics pill",
      file: file,
      line: line
    )
  }

  static func assertMapLocked(
    on cycle: CycleScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(cycle.mapLockButton, file: file, line: line)
  }

  static func assertMapUnlocked(
    on cycle: CycleScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(cycle.mapUnlockButton, file: file, line: line)
  }

  static func assertLocationSettingsAlertPresented(
    on cycle: CycleScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertAlertPresented(
      cycle.application.alerts[AlertLabel.locationSettingsTitle],
      title: AlertLabel.locationSettingsTitle,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
    XCTAssertNotNil(
      cycle.locationSettingsOpenSettingsButton(),
      "Expected the app-owned location settings alert Open Settings action",
      file: file,
      line: line
    )
    XCTAssertNotNil(
      cycle.locationSettingsIgnoreButton(),
      "Expected the app-owned location settings alert Ignore action",
      file: file,
      line: line
    )
  }

  static func assertRunning(
    on cycle: CycleScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(
      cycle.pauseButton,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
    ElementAssertions.assertExists(cycle.stopButton, file: file, line: line)
  }

  static func assertPaused(
    on cycle: CycleScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(cycle.resumeButton, file: file, line: line)
    ElementAssertions.assertExists(cycle.stopButton, file: file, line: line)
  }

  static func assertStopConfirmationPresented(
    on cycle: CycleScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertNotNil(
      cycle.stopConfirmationStopButton(),
      "Expected the app-owned stop confirmation Stop action",
      file: file,
      line: line
    )
    XCTAssertNotNil(
      cycle.stopConfirmationCancelButton(),
      "Expected the app-owned stop confirmation Cancel action",
      file: file,
      line: line
    )
  }

  static func assertAutoPausedBanner(
    on cycle: CycleScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(
      cycle.autoPausedBanner,
      timeout: Timeouts.standard,
      file: file,
      line: line
    )
  }

  static func assertPausedAfterStopCancellation(
    on cycle: CycleScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertPaused(on: cycle, file: file, line: line)
  }
}
