//
//  SettingsScreen+Assertions.swift
//  Go CyclingUITests
//

import XCTest

extension SettingsScreen {
  func assertAllSectionLabels(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertSectionHeader(
      Copy.customizationHeader,
      id: AccessibilityID.Settings.customizationSection,
      file: file,
      line: line
    )
    assertPickerControl(
      Copy.colourPicker, id: AccessibilityID.Settings.colourPicker, file: file, line: line)
    if appIconPickerVisible() {
      assertPickerControl(
        Copy.appIconPicker, id: AccessibilityID.Settings.appIconPicker, file: file, line: line)
    }

    assertSectionHeader(
      Copy.cyclingMetricsHeader,
      id: AccessibilityID.Settings.cyclingMetricsSection,
      file: file,
      line: line
    )
    assertControl(
      Copy.preferredUnits, id: AccessibilityID.Settings.preferredUnitsLabel, file: file, line: line)
    assertControl(
      Copy.displayMetricsOnMap, id: AccessibilityID.Settings.displayMetricsOnMap, file: file,
      line: line)
    assertPickerControl(
      Copy.mapTypePicker, id: AccessibilityID.Settings.mapTypePicker, file: file, line: line)

    assertSectionHeader(
      Copy.cyclingHistoryHeader,
      id: AccessibilityID.Settings.cyclingHistorySection,
      file: file,
      line: line
    )
    assertControl(
      Copy.routeCategorizationEnabled,
      id: AccessibilityID.Settings.routeCategorizationEnabled,
      file: file,
      line: line
    )
    assertControl(
      Copy.deletionEnabled, id: AccessibilityID.Settings.deletionEnabled, file: file, line: line)
    assertControl(
      Copy.deletionConfirmationAlert,
      id: AccessibilityID.Settings.deletionConfirmationAlert,
      file: file,
      line: line
    )

    assertSectionHeader(
      Copy.cyclingHeader,
      id: AccessibilityID.Settings.cyclingSection,
      file: file,
      line: line
    )
    assertControl(
      Copy.disableAutoLock, id: AccessibilityID.Settings.disableAutoLock, file: file, line: line)
    assertControl(
      Copy.autoPauseWhenStopped, id: AccessibilityID.Settings.autoPauseWhenStopped, file: file,
      line: line)

    assertSectionHeader(
      Copy.syncHeader,
      id: AccessibilityID.Settings.syncSection,
      file: file,
      line: line
    )
    assertSwitchRow(
      title: Copy.iCloudTitle,
      subtitle: Copy.iCloudSubtitle,
      id: AccessibilityID.Settings.iCloudSync,
      file: file,
      line: line
    )
    assertSwitchRow(
      title: Copy.healthTitle,
      subtitle: Copy.healthSubtitle,
      id: AccessibilityID.Settings.healthSync,
      file: file,
      line: line
    )

    assertSectionHeader(
      Copy.aboutHeader,
      id: AccessibilityID.Settings.aboutSection,
      file: file,
      line: line
    )
    assertControl(
      Copy.appVersion, id: AccessibilityID.Settings.appVersionLabel, file: file, line: line)
    assertControl(Copy.openSource, id: AccessibilityID.Settings.openSource, file: file, line: line)
    assertControl(Copy.share, id: AccessibilityID.Settings.share, file: file, line: line)
    assertControl(Copy.review, id: AccessibilityID.Settings.review, file: file, line: line)

    assertSectionHeader(
      Copy.supportHeader,
      id: AccessibilityID.Settings.supportSection,
      file: file,
      line: line
    )
    assertControl(
      Copy.privacyPolicy, id: AccessibilityID.Settings.privacyPolicy, file: file, line: line)
    assertControl(
      Copy.termsAndConditions, id: AccessibilityID.Settings.termsAndConditions, file: file,
      line: line)

    assertSectionHeader(
      Copy.resetHeader,
      id: AccessibilityID.Settings.resetSection,
      file: file,
      line: line
    )
    assertControl(
      Copy.resetToDefaultSettings,
      id: AccessibilityID.Settings.resetDefaultSettingsButton,
      file: file,
      line: line
    )
    assertControl(
      Copy.deleteAllStoredRoutes,
      id: AccessibilityID.Settings.deleteAllRoutesButton,
      file: file,
      line: line
    )
    assertControl(
      Copy.resetStoredStatistics,
      id: AccessibilityID.Settings.resetStatisticsButton,
      file: file,
      line: line
    )

    assertSectionHeader(
      Copy.privacyHeader,
      id: AccessibilityID.Settings.privacySection,
      file: file,
      line: line
    )
    assertControl(
      Copy.shareAnonymousAnalytics,
      id: AccessibilityID.Settings.shareAnonymousAnalytics,
      file: file,
      line: line
    )
    assertFooterVisible(file: file, line: line)
  }

  func assertSmokeSampleNonDefaults(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertEqual(
      pickerValue(controlID: AccessibilityID.Settings.colourPicker),
      NonDefaults.colour,
      "Expected smoke sample colour before reset",
      file: file,
      line: line
    )
    assertSegmentSelected(Copy.imperialUnits, file: file, line: line)
    assertSwitch(
      AccessibilityID.Settings.routeCategorizationEnabled,
      isOn: !Defaults.routeCategorizationEnabled,
      file: file,
      line: line
    )
  }

  func assertSmokeFactoryDefaults(
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    scrollToTop()
    XCTAssertEqual(
      pickerValue(controlID: AccessibilityID.Settings.colourPicker),
      Defaults.colour,
      "Expected default colour",
      file: file,
      line: line
    )
    assertSegmentSelected(Copy.metricUnits, file: file, line: line)
    assertSwitch(
      AccessibilityID.Settings.routeCategorizationEnabled,
      isOn: Defaults.routeCategorizationEnabled,
      file: file,
      line: line
    )
  }

  func assertFactoryDefaults(
    excludingPrivacy: Bool = false,
    syncSnapshot: SyncToggleState? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertEqual(
      pickerValue(controlID: AccessibilityID.Settings.colourPicker),
      Defaults.colour,
      "Expected default colour",
      file: file,
      line: line
    )

    if appIconPickerVisible() {
      XCTAssertEqual(
        pickerValue(controlID: AccessibilityID.Settings.appIconPicker),
        Defaults.appIcon,
        "Expected default app icon",
        file: file,
        line: line
      )
    }

    assertSegmentSelected(Copy.metricUnits, file: file, line: line)
    assertSwitch(
      AccessibilityID.Settings.displayMetricsOnMap,
      isOn: Defaults.displayMetricsOnMap,
      file: file,
      line: line
    )
    XCTAssertEqual(
      pickerValue(controlID: AccessibilityID.Settings.mapTypePicker),
      Defaults.mapType,
      "Expected default map type",
      file: file,
      line: line
    )
    assertSwitch(
      AccessibilityID.Settings.routeCategorizationEnabled,
      isOn: Defaults.routeCategorizationEnabled,
      file: file,
      line: line
    )
    assertSwitch(
      AccessibilityID.Settings.deletionEnabled,
      isOn: Defaults.deletionEnabled,
      file: file,
      line: line
    )
    assertSwitch(
      AccessibilityID.Settings.deletionConfirmationAlert,
      isOn: Defaults.deletionConfirmationAlert,
      file: file,
      line: line
    )
    assertSwitch(
      AccessibilityID.Settings.disableAutoLock,
      isOn: Defaults.disableAutoLock,
      file: file,
      line: line
    )
    assertSwitch(
      AccessibilityID.Settings.autoPauseWhenStopped,
      isOn: Defaults.autoPauseWhenStopped,
      file: file,
      line: line
    )

    // Sync toggle on/off state is environment-dependent; smoke only verifies unchanged-after-reset.
    if let syncSnapshot {
      XCTAssertEqual(
        captureSyncToggleStates(),
        syncSnapshot,
        "Expected Sync toggles to remain unchanged after reset",
        file: file,
        line: line
      )
    }

    let version = appVersionLabel()
    XCTAssertFalse(
      version.isEmpty,
      "Expected App Version label to include a semver value",
      file: file,
      line: line
    )
    XCTAssertNotNil(
      version.range(of: Defaults.semverPattern, options: .regularExpression),
      "Expected App Version to match x.x.x, got: \(version)",
      file: file,
      line: line
    )

    if !excludingPrivacy {
      assertTelemetryEnabled(Defaults.telemetryEnabled, file: file, line: line)
    }
  }

  func assertTelemetryEnabled(
    _ enabled: Bool,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertSwitch(
      AccessibilityID.Settings.shareAnonymousAnalytics,
      isOn: enabled,
      file: file,
      line: line
    )
  }

  private func assertSwitchRow(
    title: String,
    subtitle: String,
    id: String,
    file: StaticString,
    line: UInt
  ) {
    scrollUntilVisible(application.staticTexts[title], file: file, line: line)
    assertControl(
      title,
      id: id == AccessibilityID.Settings.iCloudSync
        ? AccessibilityID.Settings.iCloudTitle
        : AccessibilityID.Settings.healthTitle, file: file, line: line)
    assertControl(
      subtitle,
      id: id == AccessibilityID.Settings.iCloudSync
        ? AccessibilityID.Settings.iCloudSubtitle
        : AccessibilityID.Settings.healthSubtitle, file: file, line: line)
    assertSwitchExists(id, file: file, line: line)
  }

  private func assertSwitchExists(
    _ controlID: String,
    file: StaticString,
    line: UInt
  ) {
    let toggle = switchControl(controlID)
    scrollUntilVisible(toggle, file: file, line: line)
    ElementAssertions.assertExists(toggle, timeout: Timeouts.standard, file: file, line: line)
  }

  private func assertPickerControl(
    _ label: String,
    id: String,
    file: StaticString,
    line: UInt
  ) {
    let element = control(id)
    scrollUntilVisible(element, file: file, line: line)
    ElementAssertions.assertContainsLabel(
      element,
      label,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
  }

  private func assertControl(
    _ label: String,
    id: String,
    file: StaticString,
    line: UInt
  ) {
    let element = control(id)
    scrollUntilVisible(element, file: file, line: line)
    if element.label == label {
      return
    }
    ElementAssertions.assertContainsLabel(
      element,
      label,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
  }

  private func assertSectionHeader(
    _ label: String,
    id: String,
    file: StaticString,
    line: UInt
  ) {
    let element = control(id)
    scrollUntilVisible(element, file: file, line: line)
    ElementAssertions.assertLabel(
      element,
      equals: label,
      timeout: Timeouts.short,
      file: file,
      line: line
    )
  }

  private func assertFooterVisible(
    file: StaticString,
    line: UInt
  ) {
    let element = control(AccessibilityID.Settings.privacyFooter)
    scrollUntilVisible(element, file: file, line: line)
    ElementAssertions.assertContainsLabel(
      element,
      String(Copy.privacyFooter.prefix(120)),
      timeout: Timeouts.short,
      file: file,
      line: line
    )
  }

  private func assertSwitch(
    _ controlID: String,
    isOn: Bool,
    file: StaticString,
    line: UInt
  ) {
    let toggle = switchControl(controlID)
    scrollUntilVisible(toggle, file: file, line: line)
    ElementAssertions.assertExists(toggle, timeout: Timeouts.standard, file: file, line: line)
    XCTAssertEqual(
      switchIsOn(toggle),
      isOn,
      "Expected \(controlID) to be \(isOn ? "on" : "off")",
      file: file,
      line: line
    )
  }

  private func assertSegmentSelected(
    _ label: String,
    file: StaticString,
    line: UInt
  ) {
    let picker = control(AccessibilityID.Settings.preferredUnitsPicker)
    scrollUntilVisible(picker, file: file, line: line)
    let segment = root.buttons[label]
    scrollUntilVisible(segment, file: file, line: line)
    ElementAssertions.assertExists(segment, timeout: Timeouts.standard, file: file, line: line)
    XCTAssertTrue(
      segment.isSelected,
      "Expected \(label) units segment to be selected",
      file: file,
      line: line
    )
  }
}
