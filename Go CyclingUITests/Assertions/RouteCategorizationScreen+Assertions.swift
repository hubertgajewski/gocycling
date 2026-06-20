//
//  RouteCategorizationScreen+Assertions.swift
//  Go CyclingUITests
//

import XCTest

extension RouteCategorizationScreen {
  func assertPresented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(
      titleElement,
      timeout: Timeouts.standard,
      "Expected the Categorize Your Route sheet identifier",
      file: file,
      line: line
    )
    ElementAssertions.assertExists(
      application.staticTexts[Copy.title],
      timeout: Timeouts.short,
      "Expected the Categorize Your Route sheet title",
      file: file,
      line: line
    )
  }

  func assertDismissed(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertNotExists(
      titleElement,
      timeout: Timeouts.standard,
      "Expected the categorization sheet to dismiss after saving",
      file: file,
      line: line
    )
  }

  func assertLabels(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertPresented(file: file, line: line)
    ElementAssertions.assertExists(
      useExistingCategorySegment,
      file: file,
      line: line
    )
    ElementAssertions.assertExists(
      createNewCategorySegment,
      file: file,
      line: line
    )
    ElementAssertions.assertExists(
      application.staticTexts[Copy.enterCategoryName],
      file: file,
      line: line
    )
    ElementAssertions.assertExists(
      application.buttons[Copy.save],
      file: file,
      line: line
    )
    ElementAssertions.assertExists(
      application.buttons[
        AccessibilityID.RouteCategorization.saveWithoutCategoryButton
      ],
      file: file,
      line: line
    )
  }
}
