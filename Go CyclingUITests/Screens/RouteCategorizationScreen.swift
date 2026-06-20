//
//  RouteCategorizationScreen.swift
//  Go CyclingUITests
//

import XCTest

/// Screen object for the post-ride Categorize Your Route sheet.
final class RouteCategorizationScreen {
  private enum Copy {
    static let categoryNamePlaceholder = "Category Name"
    static let noSavedCategories = "There are no saved categories."
    static let enterCategoryName = "Enter your new category name"
  }

  let application: XCUIApplication

  init(app: XCUIApplication) {
    self.application = app
  }

  func saveWithoutCategory(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ensurePresented(file: file, line: line)
    let button = application.buttons[AccessibilityID.RouteCategorization.saveWithoutCategoryButton]
    ElementAssertions.assertExists(button, timeout: Timeouts.short, file: file, line: line)
    button.tap()
    ensureDismissed(file: file, line: line)
  }

  func saveNewCategory(
    named name: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ensurePresented(file: file, line: line)
    ensureCreateNewCategorySelected(file: file, line: line)
    ensureCategoryNameFieldReady(file: file, line: line)

    let field = categoryNameField
    field.tap()
    ensureCategoryNameFieldFocused(file: file, line: line)
    field.typeText(name)
    ElementAssertions.assertValue(
      field,
      equals: name,
      file: file,
      line: line
    )

    dismissKeyboardIfPresent()
    tapSaveWhenEnabled(file: file, line: line)
    ensureDismissed(file: file, line: line)
  }

  func selectExistingCategory(
    named name: String,
    at index: Int,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ensurePresented(file: file, line: line)
    selectUseExistingCategorySegment(file: file, line: line)
    ensureUseExistingCategorySelected(file: file, line: line)
    ensureExistingCategoryPreselected(named: name, at: index, file: file, line: line)
    tapSaveWhenEnabled(file: file, line: line)
    ensureDismissed(file: file, line: line)
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

  private func ensurePresented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    RouteCategorizationScreenAssertions.assertPresented(on: self, file: file, line: line)
  }

  private func ensureCreateNewCategorySelected(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(createNewCategorySegment, file: file, line: line)
    ElementAssertions.assertExists(categoryNameField, file: file, line: line)
  }

  private func selectUseExistingCategorySegment(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let segment = useExistingCategorySegment
    ElementAssertions.assertExists(segment, file: file, line: line)
    segment.tap()
  }

  private func ensureUseExistingCategorySelected(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
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
  }

  private func ensureCategoryNameFieldReady(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
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
  }

  private func ensureCategoryNameFieldFocused(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertKeyboardVisible(
      application.keyboards.firstMatch,
      file: file,
      line: line
    )
  }

  private func ensureExistingCategoryPreselected(
    named name: String,
    at index: Int,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let row = existingCategoryRow(at: index)
    ElementAssertions.assertExists(
      row,
      timeout: Timeouts.short,
      "Expected existing category row at index \(index)",
      file: file,
      line: line
    )
    ElementAssertions.assertContainsLabel(row, name, file: file, line: line)
    ElementAssertions.assertSelected(row, file: file, line: line)
  }

  private func ensureDismissed(
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
