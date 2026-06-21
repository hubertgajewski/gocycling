//
//  StatisticsScreen.swift
//  Go CyclingUITests
//

import XCTest

/// Screen object for Statistics tab queries.
final class StatisticsScreen {
  enum Copy {
    static let navigationTitle = "Cycling Statistics"

    static let cyclingChartsHeader = "Cycling Charts"
    static let cyclingRecordsHeader = "Cycling Records"
    static let activityAwardsHeader = "Activity Awards"

    static let chartsFooter =
      "Click on a row above to view a detailed chart of that activity period. Percentage changes compare the current activity period to the previous one. This data is based on the currently saved cycling routes."
    static let recordsFooterMetric =
      "Only routes longer than 1 km are counted for the best average cycling speed record."
    static let awardsFooter =
      "Progress toward unlocking exclusive alternate app icons. Unlocked icons will not be lost when routes are deleted or statistics are reset."

    static let chartPeriodTitles = [
      "Activity in the Past 7 Days",
      "Activity in the Past 5 Weeks",
      "Activity in the Past 30 Weeks",
    ]
    static let chartMetricLabels = [
      "Distance Cycled",
      "Cycling Time",
      "Completed Routes",
    ]

    static let singleRouteRecordsHeader = "Single Route Records"
    static let cumulativeRecordsHeader = "Cummulative Records"

    static let singleRouteRecordLabels = [
      "Longest Distance Cycled",
      "Longest Cycling Time",
      "Best Average Cycling Speed",
    ]
    static let cumulativeRecordLabels = [
      "Total Distance Cycled",
      "Total Cycling Time",
      "Total Saved Cycling Routes",
    ]

    static let awardTitles = [
      "Cycle at least 10.0 km in a single route",
      "Cycle at least 25.0 km in a single route",
      "Cycle at least 50.0 km in a single route",
      "Cycle a total of at least 100.0 km",
      "Cycle a total of at least 250.0 km",
      "Cycle a total of at least 500.0 km",
    ]

    static let awardProgressSuffix = "% Complete"
  }

  let application: XCUIApplication

  init(app: XCUIApplication) {
    self.application = app
  }

  var root: XCUIElement {
    application.descendants(matching: .any)
      .matching(identifier: AccessibilityID.MainTab.statisticsContent)
      .firstMatch
  }

  func staticText(_ label: String) -> XCUIElement {
    root.staticTexts.matching(NSPredicate(format: "label == %@", label)).firstMatch
  }

  func scrollUntilVisible(
    _ element: XCUIElement,
    maxSwipes: Int = 12,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    if element.waitForExistence(timeout: Timeouts.brief) {
      return
    }

    var swipes = 0
    while swipes < maxSwipes {
      application.swipeUp()
      swipes += 1
      if element.waitForExistence(timeout: Timeouts.poll) {
        return
      }
    }

    ElementAssertions.assertExists(element, file: file, line: line)
  }
}
