//
//  ElementAssertions.swift
//  Go CyclingUITests
//

import XCTest

/// Generic XCTest / XCUIElement expectation helpers.
enum ElementAssertions {
  static func assertExists(
    _ element: XCUIElement,
    timeout: TimeInterval = Timeouts.standard,
    _ message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertTrue(
      element.waitForExistence(timeout: timeout),
      message ?? "Expected \(element) to exist within \(timeout) seconds",
      file: file,
      line: line
    )
  }

  static func assertNotExists(
    _ element: XCUIElement,
    timeout: TimeInterval = Timeouts.short,
    _ message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let predicate = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
    XCTAssertEqual(
      result,
      XCTWaiter.Result.completed,
      message ?? "Expected \(element) to disappear within \(timeout) seconds",
      file: file,
      line: line
    )
  }

  static func assertHittable(
    _ element: XCUIElement,
    timeout: TimeInterval = Timeouts.standard,
    _ message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let predicate = NSPredicate(format: "exists == true AND hittable == true")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
    XCTAssertEqual(
      result,
      XCTWaiter.Result.completed,
      message ?? "Expected \(element) to be hittable within \(timeout) seconds",
      file: file,
      line: line
    )
  }

  static func assertEnabled(
    _ element: XCUIElement,
    timeout: TimeInterval = Timeouts.standard,
    _ message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertExists(element, timeout: timeout, message, file: file, line: line)
    XCTAssertTrue(
      element.isEnabled,
      message ?? "Expected \(element) to be enabled",
      file: file,
      line: line
    )
  }

  static func assertDisabled(
    _ element: XCUIElement,
    timeout: TimeInterval = Timeouts.standard,
    _ message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertExists(element, timeout: timeout, message, file: file, line: line)
    XCTAssertFalse(
      element.isEnabled,
      message ?? "Expected \(element) to be disabled",
      file: file,
      line: line
    )
  }

  static func assertLabel(
    _ element: XCUIElement,
    equals expected: String,
    timeout: TimeInterval = Timeouts.standard,
    _ message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertExists(element, timeout: timeout, file: file, line: line)
    XCTAssertEqual(
      element.label,
      expected,
      message ?? "Expected \(element) label to be \(expected)",
      file: file,
      line: line
    )
  }

  static func assertValue(
    _ element: XCUIElement,
    equals expected: String,
    timeout: TimeInterval = Timeouts.standard,
    _ message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertExists(element, timeout: timeout, file: file, line: line)
    XCTAssertEqual(
      element.value as? String,
      expected,
      message ?? "Expected \(element) value to be \(expected)",
      file: file,
      line: line
    )
  }

  static func assertPlaceholder(
    _ element: XCUIElement,
    equals expected: String,
    timeout: TimeInterval = Timeouts.short,
    _ message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertExists(element, timeout: timeout, file: file, line: line)
    XCTAssertEqual(
      element.placeholderValue,
      expected,
      message ?? "Expected \(element) placeholder to be \(expected)",
      file: file,
      line: line
    )
  }

  static func assertKeyboardVisible(
    _ keyboard: XCUIElement,
    timeout: TimeInterval = Timeouts.short,
    _ message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertExists(
      keyboard,
      timeout: timeout,
      message ?? "Expected the software keyboard to be visible",
      file: file,
      line: line
    )
  }

  static func assertContainsLabel(
    _ element: XCUIElement,
    _ substring: String,
    timeout: TimeInterval = Timeouts.short,
    _ message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertExists(element, timeout: timeout, file: file, line: line)
    XCTAssertTrue(
      element.label.contains(substring),
      message ?? "Expected \(element) label to contain \(substring), got: \(element.label)",
      file: file,
      line: line
    )
  }

  static func assertSelected(
    _ element: XCUIElement,
    timeout: TimeInterval = Timeouts.short,
    _ message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertExists(element, timeout: timeout, file: file, line: line)
    XCTAssertTrue(
      element.images["checkmark"].exists,
      message ?? "Expected \(element) to show a selected checkmark",
      file: file,
      line: line
    )
  }

  static func assertAlertPresented(
    _ alert: XCUIElement,
    title expectedTitle: String,
    timeout: TimeInterval = Timeouts.short,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertExists(
      alert,
      timeout: timeout,
      "Expected alert titled \(expectedTitle)",
      file: file,
      line: line
    )
  }
}
