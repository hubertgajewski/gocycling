//
//  PreferencesICloudSyncTests.swift
//  Go CyclingTests
//

import Foundation
import Testing

@testable import Go_Cycling

@Suite("Preferences iCloud sync", .serialized)
@MainActor
struct PreferencesICloudSyncTests {

  @Test("uses predictable defaults for UI-testing isolated init")
  func usesPredictableDefaultsForUITestingIsolatedInit() async {
    let snapshot = await PersistedStoreSnapshot(keys: preferenceICloudStoreKeys)
    defer { snapshot.restore() }
    clearPreferenceStores()

    let preferences = Preferences(arguments: [UITesting.launchArgument])

    #expect(preferences.usingMetric == true)
    #expect(preferences.displayingMetrics == true)
    #expect(preferences.colourChoiceConverted == .blue)
    #expect(preferences.largeMetrics == true)
    #expect(preferences.sortingChoiceConverted == .dateDescending)
    #expect(preferences.deletionConfirmation == true)
    #expect(preferences.deletionEnabled == true)
    #expect(preferences.iconIndex == 0)
    #expect(preferences.namedRoutes == true)
    #expect(preferences.selectedRoute == "")
    #expect(preferences.iCloudOn == false)
    #expect(preferences.autoLockDisabled == false)
    #expect(preferences.healthSyncEnabled == false)
    #expect(preferences.autoPauseEnabled == true)
    #expect(preferences.telemetryEnabled == true)
    #expect(preferences.mapTypeChoiceConverted == .standard)
    #expect(UserDefaults.standard.object(forKey: "didSetupPreferences") == nil)
    #expect(UserDefaults.standard.object(forKey: "metric") == nil)
    #expect(UserDefaults.standard.object(forKey: Preferences.telemetryEnabledKey) == nil)
  }

  @Test("reports iCloud unavailable when sync is on but ubiquity token is missing")
  func reportsICloudUnavailableWhenSyncIsOnButUbiquityTokenIsMissing() async {
    guard FileManager.default.ubiquityIdentityToken == nil else {
      return
    }

    let snapshot = await PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    UserDefaults.standard.set(true, forKey: iCloudSyncPreferenceKey)
    #expect(Preferences.iCloudAvailable() == false)
  }

  @Test("writes default preferences to cloud on first launch when iCloud sync is enabled")
  func writesDefaultPreferencesToCloudOnFirstLaunchWhenICloudSyncIsEnabled() async {
    guard iCloudKeyValueSyncAvailableForTests() else {
      // TODO(#24): Replace runtime guard with deterministic unavailable-store coverage.
      return
    }

    let snapshot = await PersistedStoreSnapshot(keys: preferenceICloudStoreKeys)
    defer { snapshot.restore() }
    clearPreferenceStores()
    UserDefaults.standard.set(true, forKey: iCloudSyncPreferenceKey)

    let preferences = Preferences()

    #expect(preferences.usingMetric == true)
    #expect(preferences.colourChoiceConverted == .blue)
    #expect(preferences.sortingChoiceConverted == .dateDescending)
    #expect(UserDefaults.standard.bool(forKey: "didSetupPreferences") == true)
    #expect(NSUbiquitousKeyValueStore.default.bool(forKey: "didSetupPreferences") == true)
    #expect(NSUbiquitousKeyValueStore.default.bool(forKey: "metric") == true)
    #expect(
      NSUbiquitousKeyValueStore.default.string(forKey: "colour") == ColourChoice.blue.rawValue)
  }

  @Test("syncs local values to cloud when only local store is initialized")
  func syncsLocalValuesToCloudWhenOnlyLocalStoreIsInitialized() async {
    guard iCloudKeyValueSyncAvailableForTests() else {
      // TODO(#24): Replace runtime guard with deterministic unavailable-store coverage.
      return
    }

    let snapshot = await PersistedStoreSnapshot(keys: preferenceICloudStoreKeys)
    defer { snapshot.restore() }
    clearPreferenceStores()
    seedLocalOnlyInitializedStore(metric: false, colour: ColourChoice.orange.rawValue)

    _ = Preferences()

    #expect(UserDefaults.standard.bool(forKey: "metric") == false)
    #expect(UserDefaults.standard.string(forKey: "colour") == ColourChoice.orange.rawValue)
    #expect(UserDefaults.standard.bool(forKey: "didSetupPreferences") == true)
    #expect(NSUbiquitousKeyValueStore.default.bool(forKey: "didSetupPreferences") == true)
    #expect(NSUbiquitousKeyValueStore.default.bool(forKey: "metric") == false)
    #expect(
      NSUbiquitousKeyValueStore.default.string(forKey: "colour") == ColourChoice.orange.rawValue)
  }

  @Test("syncs cloud values into local storage when only cloud store is initialized")
  func syncsCloudValuesIntoLocalStorageWhenOnlyCloudStoreIsInitialized() async {
    guard iCloudKeyValueSyncAvailableForTests() else {
      // TODO(#24): Replace runtime guard with deterministic unavailable-store coverage.
      return
    }

    let snapshot = await PersistedStoreSnapshot(keys: preferenceICloudStoreKeys)
    defer { snapshot.restore() }
    clearPreferenceStores()
    seedCloudOnlyInitializedStore(metric: false, colour: ColourChoice.red.rawValue)

    let preferences = Preferences()

    #expect(preferences.usingMetric == false)
    #expect(preferences.colourChoiceConverted == .red)
    #expect(UserDefaults.standard.bool(forKey: "didSetupPreferences") == true)
    #expect(UserDefaults.standard.bool(forKey: "metric") == false)
    #expect(UserDefaults.standard.string(forKey: "colour") == ColourChoice.red.rawValue)
  }

  @Test("syncs cloud values into local storage when both stores are initialized")
  func syncsCloudValuesIntoLocalStorageWhenBothStoresAreInitialized() async {
    guard iCloudKeyValueSyncAvailableForTests() else {
      // TODO(#24): Replace runtime guard with deterministic unavailable-store coverage.
      return
    }

    let snapshot = await PersistedStoreSnapshot(keys: preferenceICloudStoreKeys)
    defer { snapshot.restore() }
    clearPreferenceStores()
    seedBothStoresInitialized(
      localMetric: true,
      localColour: ColourChoice.blue.rawValue,
      cloudMetric: false,
      cloudColour: ColourChoice.red.rawValue,
      iCloudOn: true
    )

    let preferences = Preferences()

    #expect(preferences.usingMetric == false)
    #expect(preferences.colourChoiceConverted == .red)
    #expect(UserDefaults.standard.bool(forKey: "metric") == false)
    #expect(UserDefaults.standard.string(forKey: "colour") == ColourChoice.red.rawValue)
  }

  @Test("refreshing iCloud sync on a status-3 store pulls cloud values locally")
  func refreshingICloudSyncOnStatus3StorePullsCloudValuesLocally() async {
    guard iCloudKeyValueSyncAvailableForTests() else {
      // TODO(#24): Replace runtime guard with deterministic unavailable-store coverage.
      return
    }

    let snapshot = await PersistedStoreSnapshot(keys: preferenceICloudStoreKeys)
    defer { snapshot.restore() }
    clearPreferenceStores()
    seedBothStoresInitialized(
      localMetric: true,
      localColour: ColourChoice.blue.rawValue,
      cloudMetric: false,
      cloudColour: ColourChoice.green.rawValue,
      iCloudOn: false
    )

    let preferences = Preferences()
    #expect(preferences.usingMetric == true)
    #expect(preferences.colourChoiceConverted == .blue)

    preferences.updateBoolPreference(preference: .iCloudSync, value: true)

    #expect(preferences.iCloudOn == true)
    #expect(preferences.usingMetric == false)
    #expect(preferences.colourChoiceConverted == .green)
    #expect(UserDefaults.standard.bool(forKey: "metric") == false)
    #expect(UserDefaults.standard.string(forKey: "colour") == ColourChoice.green.rawValue)
  }

  @Test("handles external cloud change notifications")
  func handlesExternalCloudChangeNotifications() async {
    guard iCloudKeyValueSyncAvailableForTests() else {
      // TODO(#24): Replace runtime guard with deterministic unavailable-store coverage.
      return
    }

    let snapshot = await PersistedStoreSnapshot(keys: preferenceICloudStoreKeys)
    defer { snapshot.restore() }
    clearPreferenceStores()
    seedBothStoresInitialized(
      localMetric: true,
      localColour: ColourChoice.blue.rawValue,
      cloudMetric: false,
      cloudColour: ColourChoice.red.rawValue,
      iCloudOn: true
    )

    let preferences = Preferences()
    NSUbiquitousKeyValueStore.default.set(true, forKey: "metric")
    NSUbiquitousKeyValueStore.default.set(ColourChoice.violet.rawValue, forKey: "colour")
    NSUbiquitousKeyValueStore.default.synchronize()

    preferences.keysDidChangeOnCloud(
      notification: Notification(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
    )
    await drainMainQueue()

    #expect(preferences.usingMetric == true)
    #expect(preferences.colourChoiceConverted == .violet)
    #expect(UserDefaults.standard.bool(forKey: "metric") == true)
    #expect(UserDefaults.standard.string(forKey: "colour") == ColourChoice.violet.rawValue)
  }
}

private let preferenceICloudStoreKeys = [
  "didSetupPreferences",
  "metric",
  "displayingMetrics",
  "colour",
  "largeMetrics",
  "sortingChoice",
  "deletionConfirmation",
  "deletionEnabled",
  "namedRoutes",
  "selectedRoute",
  "autoLockDisabled",
  "healthSyncEnabled",
  "autoPauseEnabled",
  "mapType",
  "iconIndex",
  iCloudSyncPreferenceKey,
  Preferences.telemetryEnabledKey,
]

private func clearPreferenceStores() {
  for key in preferenceICloudStoreKeys {
    UserDefaults.standard.removeObject(forKey: key)
    NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
  }
  NSUbiquitousKeyValueStore.default.synchronize()
}

private func seedPreferenceValues(
  metric: Bool,
  colour: String,
  in userDefaults: Bool,
  inCloud: Bool
) {
  if userDefaults {
    UserDefaults.standard.set(metric, forKey: "metric")
    UserDefaults.standard.set(colour, forKey: "colour")
    UserDefaults.standard.set(true, forKey: "displayingMetrics")
    UserDefaults.standard.set(true, forKey: "largeMetrics")
    UserDefaults.standard.set(SortChoice.dateDescending.rawValue, forKey: "sortingChoice")
    UserDefaults.standard.set(true, forKey: "deletionConfirmation")
    UserDefaults.standard.set(true, forKey: "deletionEnabled")
    UserDefaults.standard.set(true, forKey: "namedRoutes")
    UserDefaults.standard.set("", forKey: "selectedRoute")
    UserDefaults.standard.set(false, forKey: "autoLockDisabled")
    UserDefaults.standard.set(false, forKey: "healthSyncEnabled")
    UserDefaults.standard.set(true, forKey: "autoPauseEnabled")
    UserDefaults.standard.set(MapTypeChoice.standard.rawValue, forKey: "mapType")
    UserDefaults.standard.set(0, forKey: "iconIndex")
    UserDefaults.standard.set(true, forKey: Preferences.telemetryEnabledKey)
  }

  if inCloud {
    NSUbiquitousKeyValueStore.default.set(metric, forKey: "metric")
    NSUbiquitousKeyValueStore.default.set(colour, forKey: "colour")
    NSUbiquitousKeyValueStore.default.set(true, forKey: "displayingMetrics")
    NSUbiquitousKeyValueStore.default.set(true, forKey: "largeMetrics")
    NSUbiquitousKeyValueStore.default.set(
      SortChoice.dateDescending.rawValue, forKey: "sortingChoice")
    NSUbiquitousKeyValueStore.default.set(true, forKey: "deletionConfirmation")
    NSUbiquitousKeyValueStore.default.set(true, forKey: "deletionEnabled")
    NSUbiquitousKeyValueStore.default.set(true, forKey: "namedRoutes")
    NSUbiquitousKeyValueStore.default.set("", forKey: "selectedRoute")
    NSUbiquitousKeyValueStore.default.set(false, forKey: "autoLockDisabled")
    NSUbiquitousKeyValueStore.default.set(false, forKey: "healthSyncEnabled")
    NSUbiquitousKeyValueStore.default.set(true, forKey: "autoPauseEnabled")
    NSUbiquitousKeyValueStore.default.set(MapTypeChoice.standard.rawValue, forKey: "mapType")
    NSUbiquitousKeyValueStore.default.synchronize()
  }
}

private func seedLocalOnlyInitializedStore(metric: Bool, colour: String) {
  UserDefaults.standard.set(true, forKey: iCloudSyncPreferenceKey)
  UserDefaults.standard.set(true, forKey: "didSetupPreferences")
  NSUbiquitousKeyValueStore.default.removeObject(forKey: "didSetupPreferences")
  seedPreferenceValues(metric: metric, colour: colour, in: true, inCloud: false)
}

private func seedCloudOnlyInitializedStore(metric: Bool, colour: String) {
  UserDefaults.standard.set(true, forKey: iCloudSyncPreferenceKey)
  UserDefaults.standard.removeObject(forKey: "didSetupPreferences")
  NSUbiquitousKeyValueStore.default.set(true, forKey: "didSetupPreferences")
  seedPreferenceValues(metric: true, colour: ColourChoice.blue.rawValue, in: false, inCloud: false)
  seedPreferenceValues(metric: metric, colour: colour, in: false, inCloud: true)
}

private func seedBothStoresInitialized(
  localMetric: Bool,
  localColour: String,
  cloudMetric: Bool,
  cloudColour: String,
  iCloudOn: Bool
) {
  UserDefaults.standard.set(iCloudOn, forKey: iCloudSyncPreferenceKey)
  UserDefaults.standard.set(true, forKey: "didSetupPreferences")
  NSUbiquitousKeyValueStore.default.set(true, forKey: "didSetupPreferences")
  seedPreferenceValues(metric: localMetric, colour: localColour, in: true, inCloud: false)
  seedPreferenceValues(metric: cloudMetric, colour: cloudColour, in: false, inCloud: true)
}

private func drainMainQueue() async {
  await withCheckedContinuation { continuation in
    DispatchQueue.main.async {
      continuation.resume()
    }
  }
}
