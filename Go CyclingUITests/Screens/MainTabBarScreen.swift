//
//  MainTabBarScreen.swift
//  Go CyclingUITests
//

import XCTest

/// Screen object for the app shell's main tab navigation.
///
/// This is the only UI-test helper that should know how tab buttons are exposed
/// on iPhone versus iPad. It does not own tab-specific controls such as Cycle
/// start, pause, or stop buttons.
final class MainTabBarScreen {
  private let app: XCUIApplication

  init(app: XCUIApplication) {
    self.app = app
  }

  /// iPhone uses a bottom `TabBar`; iPad uses nested floating tab item buttons.
  func waitForMainChrome(timeout: TimeInterval = Wait.Timeout.appChrome) -> Bool {
    if Wait.exists(app.tabBars.firstMatch, timeout: Wait.Timeout.short) {
      return true
    }

    return Wait.exists(tabButton(.cycle), timeout: timeout)
  }

  func select(
    _ tab: MainTab,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let button = tabButton(tab)
    Wait.assertExists(button, timeout: Wait.Timeout.short, file: file, line: line)
    button.tap()
  }

  func assertSelected(
    _ tab: MainTab,
    timeout: TimeInterval = Wait.Timeout.standard,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(tabContent(tab), timeout: timeout, file: file, line: line)
  }

  private func tabButton(_ tab: MainTab) -> XCUIElement {
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

  private func tabContent(_ tab: MainTab) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: tab.contentIdentifier).firstMatch
  }
}
