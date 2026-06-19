//
//  GoCyclingUITests.swift
//  Go CyclingUITests
//
//  Created by Anthony Hopkins on 2021-03-14.
//

import XCTest

/// Existing fixture-backed UI smoke coverage.
///
/// This file keeps the pre-harness Cycle and route-save scenarios passing while
/// newer UI tests move into focused files under `Go CyclingUITests/Tests`.
final class GoCyclingUITests: GoCyclingUITestCase {
  private enum AlertLabel {
    static let openSettings = "Open Settings"
    static let ignore = "Ignore"
    static let stop = "Stop"
    static let cancel = "Cancel"
  }

  func testRouteSaveFixtureCreatesHistoryRide() throws {
    let app = launchApp(extraArguments: [LaunchArgument.routeSaveFixture])
    let mainTabs = MainTabBarScreen(app: app)

    XCTAssertTrue(mainTabs.waitForMainChrome(), "Expected Cycle tab chrome after launch")

    mainTabs.select(.history)
    mainTabs.assertSelected(.history)
    Wait.assertExists(app.staticTexts["Distance Cycled"], timeout: Wait.Timeout.fixture)

    mainTabs.select(.cycle)
    mainTabs.assertSelected(.cycle)
  }

  func testCycleControlsExposeStableAccessibilityIdentifiers() throws {
    let app = launchApp(extraArguments: [LaunchArgument.cycleControlsFixture])
    let mainTabs = MainTabBarScreen(app: app)

    XCTAssertTrue(mainTabs.waitForMainChrome(), "Expected Cycle tab chrome after launch")
    mainTabs.assertSelected(.cycle)

    Wait.assertExists(app.staticTexts[AccessibilityID.Cycle.timerDisplay])
    Wait.assertExists(app.buttons[AccessibilityID.Cycle.mapLockButton])

    app.buttons[AccessibilityID.Cycle.mapLockButton].tap()
    Wait.assertExists(app.buttons[AccessibilityID.Cycle.mapUnlockButton])

    app.buttons[AccessibilityID.Cycle.startButton].tap()

    let openSettings = alertButton(
      identifier: AccessibilityID.Cycle.locationSettingsOpenSettingsButton,
      label: AlertLabel.openSettings,
      in: app
    )
    XCTAssertNotNil(openSettings)

    let ignoreLocationAlert = alertButton(
      identifier: AccessibilityID.Cycle.locationSettingsIgnoreButton,
      label: AlertLabel.ignore,
      in: app
    )
    XCTAssertNotNil(ignoreLocationAlert)
    ignoreLocationAlert?.tap()

    let pauseButton = app.buttons[AccessibilityID.Cycle.pauseButton]
    let resumeButton = app.buttons[AccessibilityID.Cycle.resumeButton]
    XCTAssertTrue(ensureCycleIsRunning(pauseButton: pauseButton, resumeButton: resumeButton))
    Wait.assertExists(app.buttons[AccessibilityID.Cycle.stopButton])

    pauseButton.tap()
    Wait.assertExists(resumeButton)
    Wait.assertExists(app.buttons[AccessibilityID.Cycle.stopButton])

    app.buttons[AccessibilityID.Cycle.stopButton].tap()

    let confirmStop = alertButton(
      identifier: AccessibilityID.Cycle.stopConfirmationStopButton,
      label: AlertLabel.stop,
      in: app
    )
    XCTAssertNotNil(confirmStop)

    let cancelStop = alertButton(
      identifier: AccessibilityID.Cycle.stopConfirmationCancelButton,
      label: AlertLabel.cancel,
      in: app
    )
    XCTAssertNotNil(cancelStop)
    cancelStop?.tap()

    Wait.assertExists(app.buttons[AccessibilityID.Cycle.resumeButton])
  }

  private func alertButton(
    identifier: String,
    label: String,
    in app: XCUIApplication,
    timeout: TimeInterval = 3
  ) -> XCUIElement? {
    if #available(iOS 15.0, *) {
      let identifiedButton = app.buttons.matching(identifier: identifier).firstMatch
      return Wait.exists(identifiedButton, timeout: timeout) ? identifiedButton : nil
    }
    let labeledButton = app.buttons[label].firstMatch
    return Wait.exists(labeledButton, timeout: timeout) ? labeledButton : nil
  }

  private func ensureCycleIsRunning(
    pauseButton: XCUIElement,
    resumeButton: XCUIElement
  ) -> Bool {
    if Wait.exists(pauseButton, timeout: Wait.Timeout.short) {
      return true
    }
    if Wait.exists(resumeButton, timeout: 1) {
      resumeButton.tap()
      return Wait.exists(pauseButton, timeout: Wait.Timeout.short)
    }
    return false
  }
}
