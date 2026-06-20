//
//  Timeouts.swift
//  Go CyclingUITests
//

import Foundation

/// Named wait durations for UI tests.
enum Timeouts {
  /// Quick re-check while scrolling or polling for an element to appear.
  static let poll: TimeInterval = 0.5
  /// Fast first-pass check before falling back to scroll or longer waits.
  static let brief: TimeInterval = 1
  static let short: TimeInterval = 3
  static let standard: TimeInterval = 5
  static let appChrome: TimeInterval = 8
}
