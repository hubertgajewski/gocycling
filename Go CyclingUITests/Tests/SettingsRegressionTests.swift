//
//  SettingsRegressionTests.swift
//  Go CyclingUITests
//

import XCTest

/// Deeper Settings reset coverage: all adjustable non-Sync settings, Privacy policy, Sync snapshot.
final class SettingsRegressionTests: SettingsUITestCase {
  func testResetToDefaultSettingsRevertsCustomizations() throws {
    let syncSnapshot = settings.captureSyncToggleStates()
    settings.assertFactoryDefaults()

    settings.changeAllNonDefaultSettingsExceptSync()
    settings.resetToDefaultSettings(reset: reset)

    // Privacy does not reset with factory defaults — intentional app-author design choice.
    settings.assertFactoryDefaults(excludingPrivacy: true, syncSnapshot: syncSnapshot)
    settings.assertTelemetryEnabled(false)
    markTelemetryForTeardownRestore()
  }
}
