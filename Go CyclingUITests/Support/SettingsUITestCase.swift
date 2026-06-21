//
//  SettingsUITestCase.swift
//  Go CyclingUITests
//

import XCTest

/// Shared launch + settings-only reset for Settings tab UI tests.
class SettingsUITestCase: BaseUITestCase {
  private(set) var mainTabs: MainTabBarScreen!
  private(set) var settings: SettingsScreen!
  private(set) var reset: SettingsResetScreen!

  override func setUpWithError() throws {
    try super.setUpWithError()

    let launchedApp = launchApp()
    mainTabs = MainTabBarScreen(app: launchedApp)
    XCTAssertTrue(mainTabs.waitForMainChrome(), "Expected Cycle tab chrome after launch")
    ResetAppDataFlow(app: launchedApp, tabs: mainTabs)
      .run(resetting: .settingsOnly, returnTo: .settings)

    settings = SettingsScreen(app: launchedApp)
    reset = SettingsResetScreen(app: launchedApp)
  }
}
