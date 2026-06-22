//
//  CycleUITestCase.swift
//  Go CyclingUITests
//

import XCTest

/// Shared launch + Settings reset for Cycle ride UI tests.
///
/// Subclasses `BaseUITestCase` so tab-only smoke tests stay on the base class
/// without paying for delete-routes / reset-defaults setup.
class CycleUITestCase: BaseUITestCase {
  private(set) var mainTabs: MainTabBarScreen!
  private(set) var cycle: CycleScreen!
  private(set) var history: HistoryScreen!
  private(set) var categorization: RouteCategorizationScreen!

  /// Override to add launch fixtures (for example auto-pause).
  var launchExtraArguments: [String] {
    [LaunchArgument.cycleControlsFixture]
  }

  /// Override to choose which local stores Settings → Reset should clear.
  var resetAreas: ResetAppDataFlow.Areas {
    .cycleDefaults
  }

  override func setUpWithError() throws {
    try super.setUpWithError()

    // Host-side simctl grant can still leave a system sheet on first launch; XCTest's
    // default interruption handler taps "Don't Allow", which blocks route save.
    addUIInterruptionMonitor(withDescription: "Allow system location for ride smoke") { alert in
      guard SystemLocationAlert.isLocationPermissionAlert(alert) else { return false }
      return SystemLocationAlert.dismiss(alert: alert, preferDeny: false)
    }

    let launchedApp = launchApp(extraArguments: launchExtraArguments)
    SystemLocationAlert.triggerInterruptionMonitor(on: launchedApp, preferDeny: false)
    mainTabs = MainTabBarScreen(app: launchedApp)
    XCTAssertTrue(mainTabs.waitForMainChrome(), "Expected Cycle tab chrome after launch")
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .cycle),
      timeout: Timeouts.standard
    )
    ResetAppDataFlow(app: launchedApp, tabs: mainTabs).run(resetting: resetAreas)

    cycle = CycleScreen(app: launchedApp)
    history = HistoryScreen(app: launchedApp)
    // Query object only; the categorization sheet appears after a completed ride.
    categorization = RouteCategorizationScreen(app: launchedApp)
  }
}
