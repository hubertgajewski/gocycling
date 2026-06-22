//
//  StatisticsScreen+Assertions.swift
//  Go CyclingUITests
//

import XCTest

extension StatisticsScreen {
  func assertNavigationTitle(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let navigationBar = application.navigationBars[Copy.navigationTitle]
    ElementAssertions.assertExists(
      navigationBar,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
  }

  func assertCyclingChartsSectionLabels(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertSectionHeader(
      Copy.cyclingChartsHeader,
      id: AccessibilityID.Statistics.cyclingChartsSection,
      file: file,
      line: line
    )
    for (index, periodTitle) in Copy.chartPeriodTitles.enumerated() {
      assertLabeledControl(
        periodTitle,
        id: AccessibilityID.Statistics.chartPeriodIdentifiers[index],
        file: file,
        line: line
      )
    }
    for metricLabel in Copy.chartMetricLabels {
      assertStaticTextCount(
        metricLabel,
        expectedCount: Copy.chartPeriodTitles.count,
        file: file,
        line: line
      )
    }
    assertFooterVisible(
      Copy.chartsFooter,
      id: AccessibilityID.Statistics.chartsFooter,
      file: file,
      line: line
    )
  }

  func assertCyclingRecordsSectionLabels(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertSectionHeader(
      Copy.cyclingRecordsHeader,
      id: AccessibilityID.Statistics.cyclingRecordsSection,
      file: file,
      line: line
    )
    assertSectionHeader(
      Copy.singleRouteRecordsHeader,
      id: AccessibilityID.Statistics.singleRouteRecordsHeader,
      file: file,
      line: line
    )
    let singleRouteRecordIDs = [
      AccessibilityID.Statistics.recordLongestDistance,
      AccessibilityID.Statistics.recordLongestTime,
      AccessibilityID.Statistics.recordBestSpeed,
    ]
    for (index, label) in Copy.singleRouteRecordLabels.enumerated() {
      assertLabeledControl(
        label,
        id: singleRouteRecordIDs[index],
        file: file,
        line: line
      )
    }
    assertSectionHeader(
      Copy.cumulativeRecordsHeader,
      id: AccessibilityID.Statistics.cumulativeRecordsHeader,
      file: file,
      line: line
    )
    let cumulativeRecordIDs = [
      AccessibilityID.Statistics.recordTotalDistance,
      AccessibilityID.Statistics.recordTotalTime,
      AccessibilityID.Statistics.recordTotalRoutes,
    ]
    for (index, label) in Copy.cumulativeRecordLabels.enumerated() {
      assertLabeledControl(
        label,
        id: cumulativeRecordIDs[index],
        file: file,
        line: line
      )
    }
    assertFooterVisible(
      Copy.recordsFooterMetric,
      id: AccessibilityID.Statistics.recordsFooter,
      file: file,
      line: line
    )
  }

  func assertActivityAwardsSectionLabels(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertSectionHeader(
      Copy.activityAwardsHeader,
      id: AccessibilityID.Statistics.activityAwardsSection,
      file: file,
      line: line
    )
    for awardTitle in Copy.awardTitles {
      assertVisibleLabel(awardTitle, file: file, line: line)
    }
    assertAwardProgressLabelCount(
      expectedCount: Copy.awardTitles.count,
      file: file,
      line: line
    )
    assertFooterVisible(
      Copy.awardsFooter,
      id: AccessibilityID.Statistics.awardsFooter,
      file: file,
      line: line
    )
  }

  func assertSavedRideStatisticsLabels(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertNavigationTitle(file: file, line: line)
    assertCyclingChartsSectionLabels(file: file, line: line)
    assertCyclingRecordsSectionLabels(file: file, line: line)
    assertActivityAwardsSectionLabels(file: file, line: line)
  }

  private func assertVisibleLabel(
    _ label: String,
    file: StaticString,
    line: UInt
  ) {
    let element = staticText(label)
    scrollUntilVisible(element, file: file, line: line)
    ElementAssertions.assertLabel(
      element,
      equals: label,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
  }

  private func assertSectionHeader(
    _ label: String,
    id: String,
    file: StaticString,
    line: UInt
  ) {
    let element = control(id)
    scrollUntilVisible(element, file: file, line: line)
    ElementAssertions.assertExists(element, timeout: Timeouts.short, file: file, line: line)
    XCTAssertEqual(
      element.label.lowercased(),
      label.lowercased(),
      "Expected \(id) section header label to match \(label) (case-insensitive)",
      file: file,
      line: line
    )
  }

  private func assertLabeledControl(
    _ label: String,
    id: String,
    file: StaticString,
    line: UInt
  ) {
    let element = control(id)
    scrollUntilVisible(element, file: file, line: line)
    ElementAssertions.assertContainsLabel(
      element,
      label,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
  }

  private func assertFooterVisible(
    _ label: String,
    id: String,
    file: StaticString,
    line: UInt
  ) {
    let element = control(id)
    scrollUntilVisible(element, file: file, line: line)
    ElementAssertions.assertContainsLabel(
      element,
      String(label.prefix(120)),
      timeout: Timeouts.short,
      file: file,
      line: line
    )
  }

  private func assertStaticTextCount(
    _ label: String,
    expectedCount: Int,
    file: StaticString,
    line: UInt
  ) {
    scrollUntilVisible(
      control(AccessibilityID.Statistics.cyclingChartsSection),
      file: file,
      line: line
    )
    scrollUntilVisible(staticText(label), file: file, line: line)
    let matchingLabels = root.staticTexts.matching(
      NSPredicate(format: "label == %@", label)
    )
    XCTAssertEqual(
      matchingLabels.count,
      expectedCount,
      "Expected \(expectedCount) \(label) label(s) in Statistics",
      file: file,
      line: line
    )
  }

  private func assertAwardProgressLabelCount(
    expectedCount: Int,
    file: StaticString,
    line: UInt
  ) {
    let predicate = NSPredicate(format: "label CONTAINS %@", Copy.awardProgressSuffix)
    var progressTexts = root.staticTexts.matching(predicate)
    var swipes = 0
    while progressTexts.count < expectedCount && swipes < 12 {
      application.swipeUp()
      swipes += 1
      progressTexts = root.staticTexts.matching(predicate)
    }

    XCTAssertEqual(
      progressTexts.count,
      expectedCount,
      "Expected \(expectedCount) award progress label(s) in Statistics",
      file: file,
      line: line
    )
  }
}
