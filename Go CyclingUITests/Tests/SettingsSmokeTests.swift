//
//  SettingsSmokeTests.swift
//  Go CyclingUITests
//

import XCTest

/// Fast Settings tab smoke: section labels plus one sample control per settings type.
final class SettingsSmokeTests: SettingsUITestCase {
  func testSettingsTabShowsSectionLabels() throws {
    ElementAssertions.assertExists(
      mainTabs.tabContent(for: .settings),
      timeout: Timeouts.standard
    )
    settings.assertAllSectionLabels()
  }

  func testResetToDefaultSettingsRevertsSampleControls() throws {
    settings.assertSmokeFactoryDefaults()
    settings.changeSmokeSampleSettings()
    settings.assertSmokeSampleNonDefaults()
    settings.resetToDefaultSettings(reset: reset)
    settings.scrollToTop()
    settings.assertSmokeFactoryDefaults()
  }
}
