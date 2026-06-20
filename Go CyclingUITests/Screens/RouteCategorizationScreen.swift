//
//  RouteCategorizationScreen.swift
//  Go CyclingUITests
//

import XCTest

/// Screen object for the post-ride Categorize Your Route sheet.
final class RouteCategorizationScreen {
  private enum Copy {
    static let title = "Categorize Your Route"
    static let createNewCategory = "Create a New Category"
    static let useExistingCategory = "Use an Existing Category"
    static let enterCategoryName = "Enter your new category name"
    static let save = "Save"
    static let saveWithoutCategory = "Save Without a Category"
    static let categoryNamePlaceholder = "Category Name"
    static let noSavedCategories = "There are no saved categories."
  }

  private let app: XCUIApplication

  init(app: XCUIApplication) {
    self.app = app
  }

  func assertPresented(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let titleByIdentifier = app.descendants(matching: .any)
      .matching(identifier: AccessibilityID.RouteCategorization.title)
      .firstMatch
    Wait.assertExists(
      titleByIdentifier,
      timeout: Wait.Timeout.standard,
      "Expected the Categorize Your Route sheet identifier",
      file: file,
      line: line
    )
    Wait.assertExists(
      app.staticTexts[Copy.title],
      timeout: Wait.Timeout.short,
      "Expected the Categorize Your Route sheet title",
      file: file,
      line: line
    )
  }

  func assertLabels(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertPresented(file: file, line: line)
    Wait.assertExists(useExistingCategorySegment, file: file, line: line)
    Wait.assertExists(createNewCategorySegment, file: file, line: line)
    Wait.assertExists(app.staticTexts[Copy.enterCategoryName], file: file, line: line)
    Wait.assertExists(app.buttons[Copy.save], file: file, line: line)
    Wait.assertExists(
      app.buttons[AccessibilityID.RouteCategorization.saveWithoutCategoryButton],
      file: file,
      line: line
    )
  }

  func saveWithoutCategory(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertPresented(file: file, line: line)
    let button = app.buttons[AccessibilityID.RouteCategorization.saveWithoutCategoryButton]
    Wait.assertExists(button, timeout: Wait.Timeout.short, file: file, line: line)
    button.tap()
    assertDismissed(file: file, line: line)
  }

  func saveNewCategory(
    named name: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertPresented(file: file, line: line)
    assertCreateNewCategorySelected(file: file, line: line)
    assertCategoryNameFieldReady(file: file, line: line)

    let field = categoryNameField
    field.tap()
    assertCategoryNameFieldFocused(file: file, line: line)
    field.typeText(name)
    XCTAssertEqual(
      field.value as? String,
      name,
      "Expected the category name field to contain the entered text",
      file: file,
      line: line
    )

    dismissKeyboardIfPresent()
    tapSaveWhenEnabled(file: file, line: line)
    assertDismissed(file: file, line: line)
  }

  func selectExistingCategory(
    named name: String,
    at index: Int,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertPresented(file: file, line: line)
    selectUseExistingCategorySegment(file: file, line: line)
    assertUseExistingCategorySelected(file: file, line: line)
    assertExistingCategoryPreselected(named: name, at: index, file: file, line: line)
    tapSaveWhenEnabled(file: file, line: line)
    assertDismissed(file: file, line: line)
  }

  private var categoryNameField: XCUIElement {
    app.descendants(matching: .any)
      .matching(identifier: AccessibilityID.RouteCategorization.categoryNameField)
      .firstMatch
  }

  private var createNewCategorySegment: XCUIElement {
    app.descendants(matching: .any)
      .matching(identifier: AccessibilityID.RouteCategorization.createNewCategorySegment)
      .firstMatch
  }

  private var useExistingCategorySegment: XCUIElement {
    app.descendants(matching: .any)
      .matching(identifier: AccessibilityID.RouteCategorization.useExistingCategorySegment)
      .firstMatch
  }

  private func existingCategoryRow(at index: Int) -> XCUIElement {
    app.buttons[
      AccessibilityID.RouteCategorization.existingCategoryRowPrefix + "\(index)"
    ]
  }

  private func assertCreateNewCategorySelected(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(createNewCategorySegment, file: file, line: line)
    Wait.assertExists(categoryNameField, file: file, line: line)
  }

  private func selectUseExistingCategorySegment(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let segment = useExistingCategorySegment
    Wait.assertExists(segment, file: file, line: line)
    segment.tap()
  }

  private func assertUseExistingCategorySelected(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertNotExists(
      categoryNameField,
      timeout: Wait.Timeout.short,
      "Expected the new-category name field to disappear after selecting Use an Existing Category",
      file: file,
      line: line
    )
    Wait.assertNotExists(
      app.staticTexts[Copy.enterCategoryName],
      timeout: Wait.Timeout.short,
      file: file,
      line: line
    )
    Wait.assertNotExists(
      app.staticTexts[Copy.noSavedCategories],
      timeout: Wait.Timeout.short,
      "Expected at least one saved category in the existing-category list",
      file: file,
      line: line
    )
    Wait.assertExists(
      existingCategoryRow(at: 0),
      timeout: Wait.Timeout.short,
      "Expected the existing-category list to show at least one row",
      file: file,
      line: line
    )
  }

  private func assertCategoryNameFieldReady(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let field = categoryNameField
    Wait.assertExists(
      field,
      timeout: Wait.Timeout.short,
      "Expected the empty category name field with placeholder",
      file: file,
      line: line
    )
    XCTAssertEqual(
      field.placeholderValue,
      Copy.categoryNamePlaceholder,
      "Expected the Category Name placeholder on the category name field",
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

  private func assertCategoryNameFieldFocused(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertExists(
      app.keyboards.firstMatch,
      timeout: Wait.Timeout.short,
      "Expected the software keyboard after tapping the category name field",
      file: file,
      line: line
    )
  }

  private func assertExistingCategoryPreselected(
    named name: String,
    at index: Int,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let row = existingCategoryRow(at: index)
    Wait.assertExists(
      row,
      timeout: Wait.Timeout.short,
      "Expected existing category row at index \(index)",
      file: file,
      line: line
    )
    XCTAssertTrue(
      row.label.contains(name),
      "Expected existing category row \(index) to be \(name), got: \(row.label)",
      file: file,
      line: line
    )
    XCTAssertTrue(
      row.images["checkmark"].exists,
      "Expected \(name) to already be selected in the existing category list",
      file: file,
      line: line
    )
  }

  private func assertDismissed(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    Wait.assertNotExists(
      app.descendants(matching: .any)
        .matching(identifier: AccessibilityID.RouteCategorization.title)
        .firstMatch,
      timeout: Wait.Timeout.standard,
      "Expected the categorization sheet to dismiss after saving",
      file: file,
      line: line
    )
  }

  private func dismissKeyboardIfPresent() {
    let keyboard = app.keyboards.firstMatch
    guard keyboard.exists else { return }

    if app.keyboards.buttons["Return"].exists {
      app.keyboards.buttons["Return"].tap()
    } else if app.toolbars.buttons["Done"].exists {
      app.toolbars.buttons["Done"].tap()
    }
  }

  private func tapSaveWhenEnabled(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let saveButton = app.buttons[AccessibilityID.RouteCategorization.saveButton]
    Wait.assertExists(saveButton, file: file, line: line)
    XCTAssertTrue(
      saveButton.isEnabled,
      "Expected Save to enable before saving the category",
      file: file,
      line: line
    )
    saveButton.tap()
  }
}
