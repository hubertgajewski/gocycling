//
//  MainTab.swift
//  Go CyclingUITests
//

enum MainTab: CaseIterable {
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
