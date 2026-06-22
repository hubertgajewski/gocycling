//
//  LocationPermissionTests.swift
//  Go CyclingUITests
//

import XCTest

/// Validates the real system location permission prompt on a reset simulator.
final class LocationPermissionTests: PermissionUITestCase {
  func testSystemLocationPromptAppearsOnFirstLaunch() throws {
    let app = launchAppExpectingPermissionPrompt()
    triggerInterruptionMonitor(on: app)

    XCTAssertTrue(
      permissionPromptObserved,
      """
      Expected the system location permission alert after resetting simulator permission. \
      If no alert appeared, location was already granted on this simulator. Use the same \
      iPhone destination as ui-test-simulator-udid.sh, or run: \
      .github/scripts/ui-test-simctl-location.sh reset <simulator-udid>
      """
    )
  }
}
