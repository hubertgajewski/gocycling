//
//  WaitHelpers.swift
//  Go CyclingUITests
//

import XCTest

enum Wait {
  enum Timeout {
    static let short: TimeInterval = 3
    static let standard: TimeInterval = 5
    static let appChrome: TimeInterval = 8
    static let fixture: TimeInterval = 8
  }

  static func assertExists(
    _ element: XCUIElement,
    timeout: TimeInterval = Timeout.standard,
    _ message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let didAppear = element.waitForExistence(timeout: timeout)
    XCTAssertTrue(
      didAppear,
      message ?? "Expected \(element) to exist within \(timeout) seconds",
      file: file,
      line: line
    )
  }

  static func exists(
    _ element: XCUIElement,
    timeout: TimeInterval = Timeout.standard
  ) -> Bool {
    element.waitForExistence(timeout: timeout)
  }
}
