//
//  CycleScreen+Assertions.swift
//  Go CyclingUITests
//

import XCTest

extension CycleScreen {
  func assertReadyToStart(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(timerDisplay, file: file, line: line)
    ElementAssertions.assertExists(startButton, file: file, line: line)
    ElementAssertions.assertExists(metricsPill, file: file, line: line)
    // MKMapView accessibility identifiers are not reliably exposed to XCUITest;
    // the map lock control sits on the map overlay and proves map chrome loaded.
    ElementAssertions.assertExists(mapLockButton, file: file, line: line)
  }

  func assertDefaultMetricsDisplayed(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(metricsSpeedValue, file: file, line: line)
    ElementAssertions.assertExists(metricsDistanceValue, file: file, line: line)
    ElementAssertions.assertExists(metricsAltitudeValue, file: file, line: line)
    ElementAssertions.assertLabel(metricsSpeedValue, equals: "0.0", file: file, line: line)
    ElementAssertions.assertLabel(metricsDistanceValue, equals: "0.0", file: file, line: line)
    ElementAssertions.assertLabel(metricsAltitudeValue, equals: "0.0", file: file, line: line)
    let metricUnits = application.staticTexts["km/h"]
    if !metricUnits.waitForExistence(timeout: Timeouts.short) {
      ElementAssertions.assertExists(
        application.staticTexts["mph"],
        timeout: Timeouts.short,
        "Expected speed units to be visible in the metrics pill",
        file: file,
        line: line
      )
    }
  }

  func assertRunning(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(
      pauseButton,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
    ElementAssertions.assertExists(stopButton, file: file, line: line)
  }

  func assertPaused(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(resumeButton, file: file, line: line)
    ElementAssertions.assertExists(stopButton, file: file, line: line)
  }

  func assertReadyForNewRide(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(startButton, timeout: Timeouts.standard, file: file, line: line)
    ElementAssertions.assertNotExists(
      stopButton,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
    ElementAssertions.assertNotExists(
      pauseButton,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
    ElementAssertions.assertNotExists(
      resumeButton,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
  }

  func assertAutoPaused(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(
      autoPausedBanner,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
    assertPaused(file: file, line: line)
  }

  func assertLocationSettingsAlertPresented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertAlertPresented(
      application.alerts[AlertLabel.locationSettingsTitle],
      timeout: Timeouts.short,
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
}
