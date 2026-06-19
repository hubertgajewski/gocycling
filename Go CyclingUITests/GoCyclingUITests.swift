//
//  GoCyclingUITests.swift
//  Go CyclingUITests
//
//  Created by Anthony Hopkins on 2021-03-14.
//

import XCTest

// CI scaffolding: minimal UI smoke coverage until a follow-up issue refactors tests.
class GoCyclingUITests: XCTestCase {
  private static let uiTestingLaunchArgument = "-ui-testing"
  private static let routeSaveFixtureLaunchArgument = "-ui-testing-route-save-fixture"

  // Keep in sync with AccessibilityIdentifier.Cycle in Support/UITesting.swift.
  // UI tests stay black-box and cannot import app-only helpers.
  private enum CycleIdentifier {
    static let timerDisplay = "cycle-timer-display"
    static let mapLockButton = "cycle-map-lock-button"
    static let mapUnlockButton = "cycle-map-unlock-button"
    static let startButton = "cycle-start-button"
    static let pauseButton = "cycle-pause-button"
    static let resumeButton = "cycle-resume-button"
    static let stopButton = "cycle-stop-button"
    static let locationSettingsOpenSettingsButton =
      "cycle-location-settings-open-settings-button"
    static let locationSettingsIgnoreButton = "cycle-location-settings-ignore-button"
    static let stopConfirmationStopButton = "cycle-stop-confirmation-stop-button"
    static let stopConfirmationCancelButton = "cycle-stop-confirmation-cancel-button"
  }

  private enum MainTab {
    case cycle
    case history
    case statistics
    case settings

    var imageIdentifier: String {
      switch self {
      case .cycle: return "bicycle"
      case .history: return "clock.arrow.circlepath"
      case .statistics: return "chart.bar.xaxis"
      case .settings: return "gear"
      }
    }

    var englishLabel: String {
      switch self {
      case .cycle: return "Cycle"
      case .history: return "History"
      case .statistics: return "Statistics"
      case .settings: return "Settings"
      }
    }

    var contentIdentifier: String {
      switch self {
      case .cycle: return "main-tab-cycle"
      case .history: return "main-tab-history"
      case .statistics: return "main-tab-statistics"
      case .settings: return "main-tab-settings"
      }
    }
  }

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testMainTabBarNavigatesToAllTabs() throws {
    let app = XCUIApplication()
    app.launchArguments = [Self.uiTestingLaunchArgument]
    app.launch()

    XCTAssertTrue(waitForMainChrome(in: app), "Expected Cycle tab chrome after launch")

    XCTAssertTrue(tabContent(.cycle, in: app).waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons[CycleIdentifier.startButton].waitForExistence(timeout: 3))

    tapTab(.history, in: app)
    XCTAssertTrue(tabContent(.history, in: app).waitForExistence(timeout: 5))

    tapTab(.statistics, in: app)
    XCTAssertTrue(tabContent(.statistics, in: app).waitForExistence(timeout: 5))

    tapTab(.settings, in: app)
    XCTAssertTrue(tabContent(.settings, in: app).waitForExistence(timeout: 5))
  }

  func testRouteSaveFixtureCreatesHistoryRide() throws {
    let app = XCUIApplication()
    app.launchArguments = [
      Self.uiTestingLaunchArgument,
      Self.routeSaveFixtureLaunchArgument,
    ]
    app.launch()

    XCTAssertTrue(waitForMainChrome(in: app), "Expected Cycle tab chrome after launch")

    tapTab(.history, in: app)
    XCTAssertTrue(tabContent(.history, in: app).waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Distance Cycled"].waitForExistence(timeout: 8))

    tapTab(.cycle, in: app)
    XCTAssertTrue(tabContent(.cycle, in: app).waitForExistence(timeout: 5))
  }

  func testCycleControlsExposeStableAccessibilityIdentifiers() throws {
    let app = XCUIApplication()
    app.launchArguments = [Self.uiTestingLaunchArgument]
    app.launch()

    XCTAssertTrue(waitForMainChrome(in: app), "Expected Cycle tab chrome after launch")
    XCTAssertTrue(tabContent(.cycle, in: app).waitForExistence(timeout: 5))

    XCTAssertTrue(app.staticTexts[CycleIdentifier.timerDisplay].waitForExistence(timeout: 3))
    XCTAssertTrue(app.buttons[CycleIdentifier.mapLockButton].waitForExistence(timeout: 3))

    app.buttons[CycleIdentifier.mapLockButton].tap()
    XCTAssertTrue(app.buttons[CycleIdentifier.mapUnlockButton].waitForExistence(timeout: 3))

    app.buttons[CycleIdentifier.startButton].tap()

    let openSettings = app.buttons.matching(
      identifier: CycleIdentifier.locationSettingsOpenSettingsButton
    ).firstMatch
    XCTAssertTrue(openSettings.waitForExistence(timeout: 3))

    let ignoreLocationAlert = app.buttons.matching(
      identifier: CycleIdentifier.locationSettingsIgnoreButton
    ).firstMatch
    XCTAssertTrue(ignoreLocationAlert.waitForExistence(timeout: 3))
    ignoreLocationAlert.tap()

    let pauseButton = app.buttons[CycleIdentifier.pauseButton]
    let resumeButton = app.buttons[CycleIdentifier.resumeButton]
    guard
      let visibleCyclingControl = waitForEither(
        pauseButton,
        resumeButton,
        timeout: 3
      )
    else {
      XCTFail("Expected either Pause or Resume after dismissing the location alert")
      return
    }
    if visibleCyclingControl.identifier == CycleIdentifier.resumeButton {
      visibleCyclingControl.tap()
    }

    XCTAssertTrue(pauseButton.waitForExistence(timeout: 3))
    XCTAssertTrue(app.buttons[CycleIdentifier.stopButton].waitForExistence(timeout: 3))

    pauseButton.tap()
    XCTAssertTrue(resumeButton.waitForExistence(timeout: 3))
    XCTAssertTrue(app.buttons[CycleIdentifier.stopButton].waitForExistence(timeout: 3))

    app.buttons[CycleIdentifier.stopButton].tap()

    let confirmStop = app.buttons.matching(
      identifier: CycleIdentifier.stopConfirmationStopButton
    ).firstMatch
    XCTAssertTrue(confirmStop.waitForExistence(timeout: 3))

    let cancelStop = app.buttons.matching(
      identifier: CycleIdentifier.stopConfirmationCancelButton
    ).firstMatch
    XCTAssertTrue(cancelStop.waitForExistence(timeout: 3))
    cancelStop.tap()

    XCTAssertTrue(app.buttons[CycleIdentifier.resumeButton].waitForExistence(timeout: 3))
  }

  /// iPhone uses a bottom `TabBar`; iPad uses nested floating tab item buttons.
  private func waitForMainChrome(in app: XCUIApplication) -> Bool {
    if app.tabBars.firstMatch.waitForExistence(timeout: 2) {
      return true
    }
    return tabButton(.cycle, in: app).waitForExistence(timeout: 8)
  }

  private func tabButton(_ tab: MainTab, in app: XCUIApplication) -> XCUIElement {
    let tabBarByLabel = app.tabBars.buttons[tab.englishLabel]
    if tabBarByLabel.exists {
      return tabBarByLabel.firstMatch
    }
    let tabBarByIdentifier = app.tabBars.buttons[tab.imageIdentifier]
    if tabBarByIdentifier.exists {
      return tabBarByIdentifier.firstMatch
    }
    return app.buttons.matching(identifier: tab.imageIdentifier).firstMatch
  }

  private func tabContent(_ tab: MainTab, in app: XCUIApplication) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: tab.contentIdentifier).firstMatch
  }

  private func waitForEither(
    _ firstElement: XCUIElement,
    _ secondElement: XCUIElement,
    timeout: TimeInterval
  ) -> XCUIElement? {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if firstElement.exists {
        return firstElement
      }
      if secondElement.exists {
        return secondElement
      }
      RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }
    if firstElement.exists {
      return firstElement
    }
    if secondElement.exists {
      return secondElement
    }
    return nil
  }

  private func tapTab(_ tab: MainTab, in app: XCUIApplication) {
    let button = tabButton(tab, in: app)
    XCTAssertTrue(button.waitForExistence(timeout: 3))
    button.tap()
  }
}
