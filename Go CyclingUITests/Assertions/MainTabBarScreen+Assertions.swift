//
//  MainTabBarScreen+Assertions.swift
//  Go CyclingUITests
//

import XCTest

enum MainTabBarScreenAssertions {
  static func assertSelected(
    _ tab: MainTabBarScreen.Tab,
    on tabs: MainTabBarScreen,
    timeout: TimeInterval = Timeouts.standard,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    ElementAssertions.assertExists(
      tabs.tabContent(for: tab),
      timeout: timeout,
      file: file,
      line: line
    )
  }
}
