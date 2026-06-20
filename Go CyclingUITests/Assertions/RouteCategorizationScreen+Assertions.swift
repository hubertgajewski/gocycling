//
//  RouteCategorizationScreen+Assertions.swift
//  Go CyclingUITests
//

import XCTest

enum RouteCategorizationScreenAssertions {
  private enum Copy {
    static let title = "Categorize Your Route"
    static let enterCategoryName = "Enter your new category name"
    static let save = "Save"
  }

  static func assertPresented(
    on categorization: RouteCategorizationScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(
      categorization.titleElement,
      timeout: Timeouts.standard,
      "Expected the Categorize Your Route sheet identifier",
      file: file,
      line: line
    )
    ElementAssertions.assertExists(
      categorization.application.staticTexts[Copy.title],
      timeout: Timeouts.short,
      "Expected the Categorize Your Route sheet title",
      file: file,
      line: line
    )
  }

  static func assertLabels(
    on categorization: RouteCategorizationScreen,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertPresented(on: categorization, file: file, line: line)
    ElementAssertions.assertExists(
      categorization.useExistingCategorySegment,
      file: file,
      line: line
    )
    ElementAssertions.assertExists(
      categorization.createNewCategorySegment,
      file: file,
      line: line
    )
    ElementAssertions.assertExists(
      categorization.application.staticTexts[Copy.enterCategoryName],
      file: file,
      line: line
    )
    ElementAssertions.assertExists(
      categorization.application.buttons[Copy.save],
      file: file,
      line: line
    )
    ElementAssertions.assertExists(
      categorization.application.buttons[
        AccessibilityID.RouteCategorization.saveWithoutCategoryButton
      ],
      file: file,
      line: line
    )
  }
}
