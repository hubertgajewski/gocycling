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
    assertVisibleLabel(Copy.navigationTitle, file: file, line: line)
  }

  func assertCyclingChartsSectionLabels(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertVisibleLabel(Copy.cyclingChartsHeader, file: file, line: line)
    for periodTitle in Copy.chartPeriodTitles {
      assertVisibleLabel(periodTitle, file: file, line: line)
    }
    for metricLabel in Copy.chartMetricLabels {
      assertStaticTextCount(
        metricLabel,
        expectedCount: Copy.chartPeriodTitles.count,
        file: file,
        line: line
      )
    }
    assertVisibleLabel(Copy.chartsFooter, file: file, line: line)
  }

  func assertCyclingRecordsSectionLabels(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertVisibleLabel(Copy.cyclingRecordsHeader, file: file, line: line)
    assertVisibleLabel(Copy.singleRouteRecordsHeader, file: file, line: line)
    for label in Copy.singleRouteRecordLabels {
      assertVisibleLabel(label, file: file, line: line)
    }
    assertVisibleLabel(Copy.cumulativeRecordsHeader, file: file, line: line)
    for label in Copy.cumulativeRecordLabels {
      assertVisibleLabel(label, file: file, line: line)
    }
    assertVisibleLabel(Copy.recordsFooterMetric, file: file, line: line)
  }

  func assertActivityAwardsSectionLabels(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertVisibleLabel(Copy.activityAwardsHeader, file: file, line: line)
    for awardTitle in Copy.awardTitles {
      assertVisibleLabel(awardTitle, file: file, line: line)
    }
    assertAwardProgressLabelCount(
      expectedCount: Copy.awardTitles.count,
      file: file,
      line: line
    )
    assertVisibleLabel(Copy.awardsFooter, file: file, line: line)
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

  private func assertStaticTextCount(
    _ label: String,
    expectedCount: Int,
    file: StaticString,
    line: UInt
  ) {
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
