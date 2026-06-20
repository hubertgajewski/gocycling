//
//  RouteCategorizationScreen.swift
//  Go CyclingUITests
//

import XCTest

/// Screen object for the post-ride Categorize Your Route sheet.
final class RouteCategorizationScreen {
  enum Copy {
    static let title = "Categorize Your Route"
    static let categoryNamePlaceholder = "Category Name"
    static let noSavedCategories = "There are no saved categories."
    static let enterCategoryName = "Enter your new category name"
    static let save = "Save"
  }

  let application: XCUIApplication

  init(app: XCUIApplication) {
    self.application = app
  }

  func saveWithoutCategory(
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
    let button = application.buttons[AccessibilityID.RouteCategorization.saveWithoutCategoryButton]
    ElementAssertions.assertExists(button, timeout: Timeouts.short, file: file, line: line)
    button.tap()
    ElementAssertions.assertNotExists(
      titleElement,
      timeout: Timeouts.standard,
      "Expected the categorization sheet to dismiss after saving",
      file: file,
      line: line
    )
  }

  func saveNewCategory(
    named name: String,
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
    ElementAssertions.assertExists(createNewCategorySegment, file: file, line: line)
    ElementAssertions.assertExists(categoryNameField, file: file, line: line)

    let field = categoryNameField
    ElementAssertions.assertExists(
      field,
      timeout: Timeouts.short,
      "Expected the empty category name field with placeholder",
      file: file,
      line: line
    )
    ElementAssertions.assertPlaceholder(
      field,
      equals: Copy.categoryNamePlaceholder,
      file: file,
      line: line
    )
    let value = field.value as? String ?? ""
    XCTAssertTrue(
      value.isEmpty || value == Copy.categoryNamePlaceholder,
      "Expected the category name field to be empty before entering text, got: \(value)",
      file: file,
      line: line
    )

    field.tap()
    ElementAssertions.assertKeyboardVisible(
      application.keyboards.firstMatch,
      file: file,
      line: line
    )
    field.typeText(name)
    ElementAssertions.assertValue(
      field,
      equals: name,
      file: file,
      line: line
    )

    dismissKeyboardIfPresent()
    tapSaveWhenEnabled(file: file, line: line)
    ElementAssertions.assertNotExists(
      titleElement,
      timeout: Timeouts.standard,
      "Expected the categorization sheet to dismiss after saving",
      file: file,
      line: line
    )
  }

  func selectExistingCategory(
    named name: String,
    at index: Int,
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

    let segment = useExistingCategorySegment
    ElementAssertions.assertExists(segment, file: file, line: line)
    segment.tap()

    ElementAssertions.assertNotExists(
      categoryNameField,
      timeout: Timeouts.short,
      "Expected the new-category name field to disappear after selecting Use an Existing Category",
      file: file,
      line: line
    )
    ElementAssertions.assertNotExists(
      application.staticTexts[Copy.enterCategoryName],
      timeout: Timeouts.short,
      file: file,
      line: line
    )
    ElementAssertions.assertNotExists(
      application.staticTexts[Copy.noSavedCategories],
      timeout: Timeouts.short,
      "Expected at least one saved category in the existing-category list",
      file: file,
      line: line
    )
    ElementAssertions.assertExists(
      existingCategoryRow(at: 0),
      timeout: Timeouts.short,
      "Expected the existing-category list to show at least one row",
      file: file,
      line: line
    )

    let row = existingCategoryRow(at: index)
    ElementAssertions.assertExists(
      row,
      timeout: Timeouts.short,
      "Expected existing category row at index \(index)",
      file: file,
      line: line
    )
    ElementAssertions.assertContainsLabel(row, name, file: file, line: line)
    row.tap()

    tapSaveWhenEnabled(file: file, line: line)
    ElementAssertions.assertNotExists(
      titleElement,
      timeout: Timeouts.standard,
      "Expected the categorization sheet to dismiss after saving",
      file: file,
      line: line
    )
  }

  var titleElement: XCUIElement {
    application.descendants(matching: .any)
      .matching(identifier: AccessibilityID.RouteCategorization.title)
      .firstMatch
  }

  var categoryNameField: XCUIElement {
    application.descendants(matching: .any)
      .matching(identifier: AccessibilityID.RouteCategorization.categoryNameField)
      .firstMatch
  }

  var createNewCategorySegment: XCUIElement {
    application.descendants(matching: .any)
      .matching(identifier: AccessibilityID.RouteCategorization.createNewCategorySegment)
      .firstMatch
  }

  var useExistingCategorySegment: XCUIElement {
    application.descendants(matching: .any)
      .matching(identifier: AccessibilityID.RouteCategorization.useExistingCategorySegment)
      .firstMatch
  }

  private func existingCategoryRow(at index: Int) -> XCUIElement {
    application.buttons[
      AccessibilityID.RouteCategorization.existingCategoryRowPrefix + "\(index)"
    ]
  }

  private func dismissKeyboardIfPresent() {
    let keyboard = application.keyboards.firstMatch
    guard keyboard.exists else { return }

    if application.keyboards.buttons["Return"].exists {
      application.keyboards.buttons["Return"].tap()
    } else if application.toolbars.buttons["Done"].exists {
      application.toolbars.buttons["Done"].tap()
    }
  }

  private func tapSaveWhenEnabled(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let saveButton = application.buttons[AccessibilityID.RouteCategorization.saveButton]
    ElementAssertions.assertEnabled(
      saveButton,
      timeout: Timeouts.standard,
      "Expected Save to enable before saving the category",
      file: file,
      line: line
    )
    saveButton.tap()
  }
}
