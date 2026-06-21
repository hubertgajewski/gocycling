//
//  SettingsScreen.swift
//  Go CyclingUITests
//

import XCTest

/// Screen object for Settings tab queries and actions.
final class SettingsScreen {
  enum Copy {
    static let navigationTitle = "Settings"

    static let customizationHeader = "Customization"
    static let colourPicker = "Colour"
    static let appIconPicker = "App Icon"

    static let cyclingMetricsHeader = "Cycling Metrics"
    static let preferredUnits = "Prefered Units"
    static let imperialUnits = "Imperial"
    static let metricUnits = "Metric"
    static let displayMetricsOnMap = "Display Metrics on Map"
    static let mapTypePicker = "Map Type"

    static let cyclingHistoryHeader = "Cycling History"
    static let routeCategorizationEnabled = "Route Categorization Enabled"
    static let deletionEnabled = "Deletion Enabled"
    static let deletionConfirmationAlert = "Deletion Confirmation Alert"

    static let cyclingHeader = "Cycling"
    static let disableAutoLock = "Disable Auto-Lock"
    static let autoPauseWhenStopped = "Auto-Pause When Stopped"

    static let syncHeader = "Sync"
    static let iCloudTitle = "iCloud"
    static let iCloudSubtitle = "Sync all data with iCloud"
    static let healthTitle = "Health"
    static let healthSubtitle = "Upload data to the Health app"

    static let aboutHeader = "About the app"
    static let appVersion = "App Version"
    static let openSource = "Go Cycling is Open Source"
    static let share = "Share"
    static let review = "Review Go Cycling"

    static let supportHeader = "Support"
    static let privacyPolicy = "View Privacy Policy"
    static let termsAndConditions = "View Terms and Conditions"

    static let resetHeader = "Reset"
    static let resetToDefaultSettings = "Reset to Default Settings"
    static let deleteAllStoredRoutes = "Delete All Stored Routes"
    static let resetStoredStatistics = "Reset Stored Statistics"

    static let privacyHeader = "Privacy"
    static let shareAnonymousAnalytics = "Share Anonymous Analytics"
    static let privacyFooter =
      "Analytics are completely anonymous and contain no personal or identifiable information. They help prioritize future improvements. You can opt out at any time."
  }

  enum Defaults {
    static let colour = "Blue"
    static let routeCategorizationEnabled = true
  }

  enum NonDefaults {
    static let colour = "Red"
    static let units = Copy.imperialUnits
  }

  let application: XCUIApplication

  init(app: XCUIApplication) {
    self.application = app
  }

  var root: XCUIElement {
    application.descendants(matching: .any)
      .matching(identifier: AccessibilityID.MainTab.settingsContent)
      .firstMatch
  }

  func control(_ identifier: String) -> XCUIElement {
    application.descendants(matching: .any).matching(identifier: identifier).firstMatch
  }

  func scrollUntilVisible(
    _ element: XCUIElement,
    maxSwipes: Int = 12,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    if isVisibleOnScreen(element, afterWaiting: Timeouts.brief) {
      return
    }

    for _ in 0..<maxSwipes {
      if isVisibleOnScreen(element, afterWaiting: Timeouts.poll) {
        return
      }
      application.swipeUp()
    }

    for _ in 0..<maxSwipes {
      if isVisibleOnScreen(element, afterWaiting: Timeouts.poll) {
        return
      }
      application.swipeDown()
    }

    ElementAssertions.assertExists(element, timeout: Timeouts.standard, file: file, line: line)
  }

  private func isVisibleOnScreen(_ element: XCUIElement, afterWaiting timeout: TimeInterval) -> Bool
  {
    guard element.waitForExistence(timeout: timeout) else {
      return false
    }

    if element.isHittable {
      return true
    }

    let frame = element.frame
    guard frame.width > 0, frame.height > 0 else {
      return false
    }

    let window = application.windows.element(boundBy: 0)
    guard window.exists else {
      return false
    }

    return window.frame.intersects(frame)
  }

  /// Scroll the settings form back toward the top after reading lower sections.
  func scrollToTop(maxSwipes: Int = 8) {
    let anchor = control(AccessibilityID.Settings.colourPicker)
    for _ in 0..<maxSwipes {
      if isVisibleOnScreen(anchor, afterWaiting: Timeouts.poll) {
        return
      }
      application.swipeDown()
    }
  }

  func appIconPickerVisible() -> Bool {
    control(AccessibilityID.Settings.appIconPicker).exists
  }

  func changeSmokeSampleSettings(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    scrollToTop()
    selectNavigationPicker(
      AccessibilityID.Settings.colourPicker,
      value: NonDefaults.colour,
      file: file,
      line: line
    )
    selectUnits(NonDefaults.units, file: file, line: line)
    setSwitch(
      AccessibilityID.Settings.routeCategorizationEnabled,
      on: !Defaults.routeCategorizationEnabled,
      file: file,
      line: line
    )
  }

  func resetToDefaultSettings(
    reset: SettingsResetScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    reset.resetToDefaultSettings(file: file, line: line)
  }

  func pickerValue(controlID: String) -> String {
    let row = control(controlID)
    guard row.waitForExistence(timeout: Timeouts.brief) else {
      return ""
    }

    let parts = row.label.split(separator: ",", maxSplits: 1)
    if parts.count == 2 {
      return String(parts[1]).trimmingCharacters(in: .whitespaces)
    }
    return row.value as? String ?? ""
  }

  func isSwitchOn(_ controlID: String) -> Bool {
    let toggle = switchControl(controlID)
    guard toggle.waitForExistence(timeout: Timeouts.brief) else {
      return false
    }
    return switchIsOn(toggle)
  }

  func switchControl(_ controlID: String) -> XCUIElement {
    let container = control(controlID)
    if container.waitForExistence(timeout: Timeouts.brief) {
      let nested = container.switches.firstMatch
      if nested.waitForExistence(timeout: Timeouts.brief) {
        return nested
      }
    }

    let byIdentifier = application.switches.matching(identifier: controlID).firstMatch
    if byIdentifier.waitForExistence(timeout: Timeouts.brief) {
      return byIdentifier
    }

    return container
  }

  func switchIsOn(_ toggle: XCUIElement) -> Bool {
    if toggle.elementType == .switch {
      return switchValueIsOn(toggle)
    }

    let nested = toggle.switches.firstMatch
    if nested.waitForExistence(timeout: Timeouts.brief) {
      return switchValueIsOn(nested)
    }

    let label = toggle.label
    if label.hasSuffix(", On") {
      return true
    }
    if label.hasSuffix(", Off") {
      return false
    }

    return switchValueIsOn(toggle)
  }

  private func switchValueIsOn(_ toggle: XCUIElement) -> Bool {
    switch toggle.value as? String {
    case "1", "On", "on", "YES", "yes":
      return true
    case "0", "Off", "off", "NO", "no":
      return false
    default:
      break
    }

    if let intValue = toggle.value as? Int {
      return intValue != 0
    }

    return false
  }

  private func tapSwitch(_ toggle: XCUIElement) {
    if toggle.elementType == .switch {
      toggle.tap()
      return
    }

    let nested = toggle.switches.firstMatch
    if nested.exists {
      nested.tap()
      return
    }

    toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
  }

  private func selectUnits(
    _ units: String,
    file: StaticString,
    line: UInt
  ) {
    let picker = control(AccessibilityID.Settings.preferredUnitsPicker)
    scrollUntilVisible(picker, file: file, line: line)
    let segment = root.buttons[units]
    scrollUntilVisible(segment, file: file, line: line)
    segment.tap()
  }

  private func selectNavigationPicker(
    _ controlID: String,
    value: String,
    file: StaticString,
    line: UInt
  ) {
    let row = control(controlID)
    scrollUntilVisible(row, file: file, line: line)
    row.tap()
    selectPickerOption(value, file: file, line: line)
    dismissPickerDetailIfNeeded()
  }

  private func selectPickerOption(
    _ value: String,
    file: StaticString,
    line: UInt
  ) {
    if application.pickerWheels.firstMatch.waitForExistence(timeout: Timeouts.standard) {
      application.pickerWheels.firstMatch.adjust(toPickerWheelValue: value)
      return
    }

    let picker = application.pickers.firstMatch
    if picker.waitForExistence(timeout: Timeouts.brief) {
      let wheel = picker.pickerWheels.firstMatch
      if wheel.waitForExistence(timeout: Timeouts.brief) {
        wheel.adjust(toPickerWheelValue: value)
        return
      }
    }

    let cell = application.tables.cells.staticTexts[value].firstMatch
    if cell.waitForExistence(timeout: Timeouts.standard) {
      cell.tap()
      return
    }

    let containingCell = application.tables.cells
      .containing(NSPredicate(format: "label CONTAINS[c] %@", value))
      .firstMatch
    if containingCell.waitForExistence(timeout: Timeouts.brief) {
      containingCell.tap()
      return
    }

    let button = application.buttons[value]
    if button.waitForExistence(timeout: Timeouts.brief) {
      button.tap()
      return
    }

    let option = application.staticTexts[value]
    ElementAssertions.assertExists(option, timeout: Timeouts.standard, file: file, line: line)
    option.tap()
  }

  private func dismissPickerDetailIfNeeded() {
    let settingsBack = application.navigationBars.buttons["Settings"]
    if settingsBack.waitForExistence(timeout: Timeouts.brief) {
      settingsBack.tap()
      return
    }

    let back = application.navigationBars.buttons.firstMatch
    if back.waitForExistence(timeout: Timeouts.brief) {
      back.tap()
    }
  }

  private func setSwitch(
    _ controlID: String,
    on: Bool,
    file: StaticString,
    line: UInt
  ) {
    var toggle = switchControl(controlID)
    scrollUntilVisible(toggle, file: file, line: line)
    ElementAssertions.assertExists(toggle, timeout: Timeouts.standard, file: file, line: line)

    var attempts = 0
    while switchIsOn(toggle) != on, attempts < 3 {
      tapSwitch(toggle)
      attempts += 1
      toggle = switchControl(controlID)
      _ = toggle.waitForExistence(timeout: Timeouts.brief)
    }

    XCTAssertEqual(
      switchIsOn(toggle),
      on,
      "Expected \(controlID) to be \(on ? "on" : "off")",
      file: file,
      line: line
    )
  }
}
