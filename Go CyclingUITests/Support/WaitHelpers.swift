//
//  WaitHelpers.swift
//  Go CyclingUITests
//

import XCTest

/// Shared wait policy for UI tests.
///
/// Keeping timeouts named and centralized avoids scattered raw waits and keeps
/// future tuning explicit when simulator timing changes.
enum Wait {
  enum Timeout {
    /// Quick re-check while scrolling or polling for an element to appear.
    static let poll: TimeInterval = 0.5
    /// Fast first-pass check before falling back to scroll or longer waits.
    static let brief: TimeInterval = 1
    static let short: TimeInterval = 3
    static let standard: TimeInterval = 5
    static let appChrome: TimeInterval = 8
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
