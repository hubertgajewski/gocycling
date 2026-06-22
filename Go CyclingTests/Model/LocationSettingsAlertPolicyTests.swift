//
//  LocationSettingsAlertPolicyTests.swift
//  Go CyclingTests
//

import CoreLocation
import Testing

@testable import Go_Cycling

@Suite("LocationSettingsAlertPolicy")
struct LocationSettingsAlertPolicyTests {

  @Test("returns no alert message when location is always authorized")
  func returnsNoAlertMessageWhenLocationIsAlwaysAuthorized() {
    #expect(
      LocationSettingsAlertPolicy.alertMessage(for: .authorizedAlways) == "")
  }

  @Test("returns always-location guidance when authorized while in use")
  func returnsAlwaysLocationGuidanceWhenAuthorizedWhileInUse() {
    #expect(
      LocationSettingsAlertPolicy.alertMessage(for: .authorizedWhenInUse)
        == alwaysLocationGuidance)
  }

  @Test("returns permissions-required guidance for unavailable authorization statuses")
  func returnsPermissionsRequiredGuidanceForUnavailableAuthorizationStatuses() {
    for status in unavailableLocationAuthorizationStatuses {
      #expect(
        LocationSettingsAlertPolicy.alertMessage(for: status)
          == permissionsGuidance)
    }
  }

  @Test("cycle controls fixture does not activate with unrelated launch arguments")
  func cycleControlsFixtureDoesNotActivateWithUnrelatedLaunchArguments() {
    #expect(
      UITesting.shouldUseCycleControlsFixture(arguments: [
        "-unrelated-launch-argument"
      ]) == false)
    #expect(
      UITesting.shouldUseCycleControlsFixture(arguments: [
        UITesting.cycleControlsFixtureArgument
      ]))
  }
}

private let unavailableLocationAuthorizationStatuses: [CLAuthorizationStatus] = [
  .denied,
  .restricted,
  .notDetermined,
]

private let alwaysLocationGuidance =
  """
  Go Cycling requires your location to be set to "Always" to function while the app is not on the screen.

  Please visit your app settings and verify that location access is allowed.

  If you plan to leave your device screen on while cycling then your current location access will work.
  """

private let permissionsGuidance =
  """
  Go Cycling requires location permissions to track your cycling routes.

  Please visit your app settings and verify that location access is allowed.

  All of your location data will be stored solely on your device and will never be shared with anyone.
  """
