//
//  SystemLocationAlert.swift
//  Go CyclingUITests
//

import XCTest

/// Queries and dismisses the system location permission sheet.
///
/// On recent iOS versions the prompt is surfaced as an app interruption alert,
/// which XCTest handles most reliably through `addUIInterruptionMonitor`.
enum SystemLocationAlert {
  private static let springboardBundleID = "com.apple.springboard"

  /// Initial when-in-use prompt and legacy labels.
  private static let denyButtonLabels = [
    "Don't Allow",
    "Don\u{2019}t Allow",
  ]

  /// Declines always-on upgrade while keeping when-in-use access.
  private static let denyAlwaysUpgradeButtonLabels = [
    "Keep Only While Using App",
    "Keep Only While Using the App",
    "Keep Only While Using",
  ]

  private static let allowButtonLabels = [
    "Allow While Using App",
    "Allow While Using the App",
    "Allow Once",
    "Allow",
    "Change to Always Allow",
    "Always Allow",
  ]

  private static func normalizedForMatching(_ text: String) -> String {
    text
      .lowercased()
      .replacingOccurrences(of: "\u{2019}", with: "'")
      .replacingOccurrences(of: "\u{2018}", with: "'")
      .replacingOccurrences(of: "\u{02BC}", with: "'")
  }

  static func isLocationPermissionAlert(_ alert: XCUIElement) -> Bool {
    let label = alert.label.lowercased()
    if label.contains("location") {
      return true
    }
    let permissionButtonLabels =
      denyButtonLabels + denyAlwaysUpgradeButtonLabels + allowButtonLabels
    for buttonLabel in permissionButtonLabels where alert.buttons[buttonLabel].exists {
      return true
    }
    return matchingButton(in: alert, preferDeny: true) != nil
      || matchingButton(in: alert, preferDeny: false) != nil
  }

  @discardableResult
  static func dismiss(alert: XCUIElement, preferDeny: Bool = true) -> Bool {
    guard let button = matchingButton(in: alert, preferDeny: preferDeny) else {
      return false
    }
    button.tap()
    return true
  }

  @discardableResult
  static func dismissIfPresent(app: XCUIApplication? = nil, preferDeny: Bool = true) -> Bool {
    var dismissed = false

    if let app, let alert = visibleLocationAlert(in: app) {
      dismissed = dismiss(alert: alert, preferDeny: preferDeny) || dismissed
    }

    let springboard = XCUIApplication(bundleIdentifier: springboardBundleID)
    if let alert = visibleLocationAlert(in: springboard) {
      dismissed = dismiss(alert: alert, preferDeny: preferDeny) || dismissed
    }

    return dismissed
  }

  private static func matchingButton(in alert: XCUIElement, preferDeny: Bool) -> XCUIElement? {
    let exactLabels =
      preferDeny
      ? denyButtonLabels + denyAlwaysUpgradeButtonLabels
      : allowButtonLabels

    for label in exactLabels where alert.buttons[label].exists {
      return alert.buttons[label]
    }

    let substringMatches =
      preferDeny
      ? ["don't allow", "not allow", "keep only while using"]
      : ["allow while using", "allow once", "change to always", "always allow"]

    for index in 0..<alert.buttons.count {
      let button = alert.buttons.element(boundBy: index)
      let normalizedLabel = normalizedForMatching(button.label)
      if substringMatches.contains(where: { normalizedLabel.contains($0) }) {
        return button
      }
    }

    return nil
  }

  private static func visibleLocationAlert(in application: XCUIApplication) -> XCUIElement? {
    let alert = application.alerts.firstMatch
    guard alert.waitForExistence(timeout: 0.5), isLocationPermissionAlert(alert) else {
      return nil
    }
    return alert
  }
}
