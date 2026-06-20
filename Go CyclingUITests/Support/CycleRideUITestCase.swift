//
//  CycleRideUITestCase.swift
//  Go CyclingUITests
//

import XCTest

/// Shared launch + Settings reset for Cycle ride UI tests.
///
/// Subclasses `GoCyclingUITestCase` so tab-only smoke tests stay on the base
/// class without paying for delete-routes / reset-defaults setup.
class CycleRideUITestCase: GoCyclingUITestCase {
  private(set) var mainTabs: MainTabBarScreen!
  private(set) var cycle: CycleScreen!
  private(set) var history: HistoryScreen!
  private(set) var categorization: RouteCategorizationScreen!

  /// Override to add launch fixtures (for example auto-pause).
  var launchExtraArguments: [String] {
    [LaunchArgument.cycleControlsFixture]
  }

  override func setUpWithError() throws {
    try super.setUpWithError()

    let launchedApp = launchApp(extraArguments: launchExtraArguments)
    mainTabs = MainTabBarScreen(app: launchedApp)
    XCTAssertTrue(mainTabs.waitForMainChrome(), "Expected Cycle tab chrome after launch")
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .cycle),
      timeout: Timeouts.standard
    )
    ResetAppDataFlow(app: launchedApp, tabs: mainTabs).run()

    cycle = CycleScreen(app: launchedApp)
    history = HistoryScreen(app: launchedApp)
    // Query object only; the categorization sheet appears after a completed ride.
    categorization = RouteCategorizationScreen(app: launchedApp)
  }
}
