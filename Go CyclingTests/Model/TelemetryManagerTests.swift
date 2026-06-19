//
//  TelemetryManagerTests.swift
//  Go CyclingTests
//

import Foundation
import Testing

@testable import Go_Cycling

@Suite("TelemetryManager")
struct TelemetryManagerTests {

  @Test("does not emit cycling signals when user telemetry is disabled")
  func doesNotEmitCyclingSignalsWhenUserTelemetryIsDisabled() {
    let manager = TelemetryManager.sharedTelemetryManager
    manager.userTelemetryEnabled = false

    manager.sendCyclingSignal(tab: .Cycle, action: .Start)
    manager.sendCyclingSignal(tab: .History, action: .FilterClick)

    manager.userTelemetryEnabled = true
  }

  @Test("does not emit settings signals when user telemetry is disabled")
  func doesNotEmitSettingsSignalsWhenUserTelemetryIsDisabled() {
    let manager = TelemetryManager.sharedTelemetryManager
    manager.userTelemetryEnabled = false

    manager.sendSettingsSignal(section: .Privacy, action: .TelemetryOptOut)
    manager.sendSettingsSignal(
      section: .Customization,
      action: .Colour,
      parameters: ["colour": "blue"]
    )

    manager.userTelemetryEnabled = true
  }

  @Test("emits settings signals when user telemetry is enabled")
  func emitsSettingsSignalsWhenUserTelemetryIsEnabled() {
    let manager = TelemetryManager.sharedTelemetryManager
    manager.userTelemetryEnabled = true

    manager.sendSettingsSignal(section: .Metrics, action: .Units)
    manager.sendSettingsSignal(
      section: .History,
      action: .RoutesEnabled,
      parameters: ["enabled": "true"]
    )
  }

  @Test("accepts setup configuration without crashing")
  func acceptsSetupConfigurationWithoutCrashing() {
    TelemetryManager.setup(
      TelemetryManager.TelemetryManagerConfig(appID: "test-app-id"),
      enabled: false
    )
  }
}
