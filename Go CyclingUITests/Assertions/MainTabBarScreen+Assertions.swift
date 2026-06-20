//
//  MainTabBarScreen+Assertions.swift
//  Go CyclingUITests
//

import XCTest

extension MainTabBarScreen {
  func assertSelected(
    _ tab: Tab,
    timeout: TimeInterval = Timeouts.standard,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(
      tabContent(for: tab),
      timeout: timeout,
      file: file,
      line: line
    )
  }
}
