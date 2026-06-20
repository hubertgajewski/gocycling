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
  /// Main app tabs and the locators needed to select and verify them.
  ///
  /// `englishLabel` covers iPhone tab bars, `imageIdentifier` covers iPad
  /// floating tab buttons, and `contentIdentifier` verifies the selected root.
  enum Tab {
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
      case .cycle: return AccessibilityID.MainTab.cycleContent
      case .history: return AccessibilityID.MainTab.historyContent
      case .statistics: return AccessibilityID.MainTab.statisticsContent
      case .settings: return AccessibilityID.MainTab.settingsContent
      }
    }
  }

  private let app: XCUIApplication

  init(app: XCUIApplication) {
    self.app = app
  }

  /// iPhone uses a bottom `TabBar`; iPad uses nested floating tab item buttons.
  func waitForMainChrome(timeout: TimeInterval = Timeouts.appChrome) -> Bool {
    if app.tabBars.firstMatch.waitForExistence(timeout: Timeouts.short) {
      return true
    }

    return tabButton(.cycle).waitForExistence(timeout: timeout)
  }

  func select(
    _ tab: Tab,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let button = tabButton(tab)
    ElementAssertions.assertExists(button, timeout: Timeouts.short, file: file, line: line)
    button.tap()
  }

  func tabContent(for tab: Tab) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: tab.contentIdentifier).firstMatch
  }

  private func tabButton(_ tab: Tab) -> XCUIElement {
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
}
