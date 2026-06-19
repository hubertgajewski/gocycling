//
//  PreferencesMutationTests.swift
//  Go CyclingTests
//

import CoreData
import Foundation
import Testing

@testable import Go_Cycling

@Suite("Preferences mutation", .serialized)
@MainActor
struct PreferencesMutationTests {

  @Test("writes bool preferences to storage and published properties")
  func writesBoolPreferencesToStorageAndPublishedProperties() async {
    let snapshot = await PersistedStoreSnapshot(keys: preferenceMutationStoreKeys)
    defer { snapshot.restore() }
    seedPreferenceMutationDefaults()

    let preferences = Preferences()
    preferences.updateBoolPreference(preference: .metric, value: false)
    preferences.updateBoolPreference(preference: .displayingMetrics, value: false)
    preferences.updateBoolPreference(preference: .largeMetrics, value: false)
    preferences.updateBoolPreference(preference: .deletionConfirmation, value: false)
    preferences.updateBoolPreference(preference: .deletionEnabled, value: false)
    preferences.updateBoolPreference(preference: .namedRoutes, value: false)
    preferences.updateBoolPreference(preference: .autoLockDisabled, value: true)
    preferences.updateBoolPreference(preference: .healthSyncEnabled, value: true)
    preferences.updateBoolPreference(preference: .autoPauseEnabled, value: false)
    preferences.updateBoolPreference(preference: .telemetryEnabled, value: false)

    #expect(preferences.usingMetric == false)
    #expect(preferences.displayingMetrics == false)
    #expect(preferences.largeMetrics == false)
    #expect(preferences.deletionConfirmation == false)
    #expect(preferences.deletionEnabled == false)
    #expect(preferences.namedRoutes == false)
    #expect(preferences.autoLockDisabled == true)
    #expect(preferences.healthSyncEnabled == true)
    #expect(preferences.autoPauseEnabled == false)
    #expect(preferences.telemetryEnabled == false)
    #expect(UserDefaults.standard.bool(forKey: "metric") == false)
    #expect(UserDefaults.standard.bool(forKey: Preferences.telemetryEnabledKey) == false)
    #expect(preferences.metricsChoiceConverted == .imperial)
  }

  @Test("writes string and int preferences to storage and published properties")
  func writesStringAndIntPreferencesToStorageAndPublishedProperties() async {
    let snapshot = await PersistedStoreSnapshot(keys: preferenceMutationStoreKeys)
    defer { snapshot.restore() }
    seedPreferenceMutationDefaults()

    let preferences = Preferences()
    preferences.updateStringPreference(preference: .colour, value: ColourChoice.orange.rawValue)
    preferences.updateStringPreference(
      preference: .sortingChoice, value: SortChoice.timeDescending.rawValue)
    preferences.updateStringPreference(preference: .selectedRoute, value: "Training")
    preferences.updateStringPreference(
      preference: .mapTypeChoice, value: MapTypeChoice.hybrid.rawValue)
    preferences.updateIntPreference(preference: .iconIndex, value: 3)

    #expect(preferences.colourChoiceConverted == .orange)
    #expect(preferences.sortingChoiceConverted == .timeDescending)
    #expect(preferences.selectedRoute == "Training")
    #expect(preferences.mapTypeChoiceConverted == .hybrid)
    #expect(preferences.iconIndex == 3)
    #expect(UserDefaults.standard.string(forKey: "colour") == ColourChoice.orange.rawValue)
    #expect(UserDefaults.standard.integer(forKey: "iconIndex") == 3)
  }

  @Test("resets preferences to defaults")
  func resetsPreferencesToDefaults() async {
    let snapshot = await PersistedStoreSnapshot(keys: preferenceMutationStoreKeys)
    defer { snapshot.restore() }
    seedPreferenceMutationDefaults()

    let preferences = Preferences()
    preferences.updateBoolPreference(preference: .metric, value: false)
    preferences.updateStringPreference(preference: .colour, value: ColourChoice.red.rawValue)
    preferences.updateIntPreference(preference: .iconIndex, value: 5)

    preferences.resetPreferences()

    #expect(preferences.usingMetric == true)
    #expect(preferences.colourChoiceConverted == .blue)
    #expect(preferences.sortingChoiceConverted == .dateDescending)
    #expect(preferences.iconIndex == 0)
    #expect(UserDefaults.standard.bool(forKey: "metric") == true)
    #expect(UserDefaults.standard.string(forKey: "colour") == ColourChoice.blue.rawValue)
  }

  @Test("UI testing preference updates and reset stay in memory")
  func uiTestingPreferenceUpdatesAndResetStayInMemory() async {
    let snapshot = await PersistedStoreSnapshot(keys: preferenceMutationStoreKeys)
    defer { snapshot.restore() }
    seedPreferenceMutationDefaults()
    UserDefaults.standard.set(false, forKey: "metric")
    UserDefaults.standard.set(ColourChoice.red.rawValue, forKey: "colour")
    UserDefaults.standard.set(7, forKey: "iconIndex")

    let preferences = Preferences(arguments: [UITesting.launchArgument])
    preferences.updateBoolPreference(preference: .metric, value: false)
    preferences.updateStringPreference(preference: .colour, value: ColourChoice.orange.rawValue)
    preferences.updateIntPreference(preference: .iconIndex, value: 5)

    #expect(preferences.usingMetric == false)
    #expect(preferences.colourChoiceConverted == .orange)
    #expect(preferences.iconIndex == 5)
    #expect(UserDefaults.standard.bool(forKey: "metric") == false)
    #expect(UserDefaults.standard.string(forKey: "colour") == ColourChoice.red.rawValue)
    #expect(UserDefaults.standard.integer(forKey: "iconIndex") == 7)

    preferences.resetPreferences()

    #expect(preferences.usingMetric == true)
    #expect(preferences.colourChoiceConverted == .blue)
    #expect(preferences.iconIndex == 0)
    #expect(UserDefaults.standard.bool(forKey: "metric") == false)
    #expect(UserDefaults.standard.string(forKey: "colour") == ColourChoice.red.rawValue)
    #expect(UserDefaults.standard.integer(forKey: "iconIndex") == 7)
  }

  @Test("reports iCloud unavailable when sync preference is off")
  func reportsICloudUnavailableWhenSyncPreferenceIsOff() async {
    let snapshot = await PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    UserDefaults.standard.set(false, forKey: iCloudSyncPreferenceKey)
    #expect(Preferences.iCloudAvailable() == false)
  }

  @Test("reads stored health sync preference")
  func readsStoredHealthSyncPreference() async {
    let snapshot = await PersistedStoreSnapshot(keys: preferenceMutationStoreKeys)
    defer { snapshot.restore() }
    seedPreferenceMutationDefaults()

    UserDefaults.standard.set(true, forKey: "healthSyncEnabled")
    #expect(Preferences.storedHealthSyncEnabled() == true)

    UserDefaults.standard.set(false, forKey: "healthSyncEnabled")
    #expect(Preferences.storedHealthSyncEnabled() == false)
  }

  @Test("isolated UI tests suppress HealthKit side effects")
  func isolatedUITestsSuppressHealthKitSideEffects() async {
    let snapshot = await PersistedStoreSnapshot(keys: preferenceMutationStoreKeys)
    defer { snapshot.restore() }
    seedPreferenceMutationDefaults()

    UserDefaults.standard.set(true, forKey: "healthSyncEnabled")

    #expect(Preferences.storedHealthSyncEnabled(arguments: []) == true)
    #expect(LocationViewModel.shouldWriteHealthData(arguments: []) == true)
    #expect(SyncSettingsView.shouldRequestHealthAuthorization(whenEnabled: true, arguments: []))

    let isolatedArguments = [UITesting.launchArgument]
    #expect(Preferences.storedHealthSyncEnabled(arguments: isolatedArguments) == false)
    #expect(LocationViewModel.shouldWriteHealthData(arguments: isolatedArguments) == false)
    #expect(
      SyncSettingsView.shouldRequestHealthAuthorization(
        whenEnabled: true,
        arguments: isolatedArguments
      ) == false
    )
  }

  @Test("migrates legacy user preferences into defaults")
  func migratesLegacyUserPreferencesIntoDefaults() async {
    let snapshot = await PersistedStoreSnapshot(keys: preferenceMutationStoreKeys)
    defer { snapshot.restore() }

    let context = PersistenceController(inMemory: true).container.viewContext
    let entity = NSEntityDescription.entity(forEntityName: "UserPreferences", in: context)!
    let legacy = UserPreferences(entity: entity, insertInto: context)
    legacy.usingMetric = false
    legacy.displayingMetrics = false
    legacy.colourChoice = ColourChoice.green.rawValue
    legacy.largeMetrics = false
    legacy.sortingChoice = SortChoice.distanceAscending.rawValue
    legacy.deletionConfirmation = false
    legacy.deletionEnabled = false
    legacy.namedRoutes = false
    legacy.selectedRoute = "Commute"
    legacy.autoLockDisabled = true
    legacy.healthSyncEnabled = true
    legacy.iconIndex = 2

    let preferences = Preferences()
    preferences.initialUserPreferencesMigration(existingPreferences: legacy)

    #expect(preferences.usingMetric == false)
    #expect(preferences.displayingMetrics == false)
    #expect(preferences.colourChoiceConverted == .green)
    #expect(preferences.sortingChoiceConverted == .distanceAscending)
    #expect(preferences.selectedRoute == "Commute")
    #expect(preferences.autoLockDisabled == true)
    #expect(preferences.healthSyncEnabled == true)
    #expect(preferences.iconIndex == 2)
    #expect(preferences.iCloudOn == false)
    #expect(UserDefaults.standard.bool(forKey: "didSetupPreferences") == true)
  }

  @Test("defaults auto pause to enabled when preference key is missing")
  func defaultsAutoPauseToEnabledWhenPreferenceKeyIsMissing() async {
    let snapshot = await PersistedStoreSnapshot(keys: preferenceMutationStoreKeys)
    defer { snapshot.restore() }

    for key in preferenceMutationStoreKeys {
      UserDefaults.standard.removeObject(forKey: key)
      NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
    }
    NSUbiquitousKeyValueStore.default.synchronize()
    UserDefaults.standard.set(false, forKey: iCloudSyncPreferenceKey)
    UserDefaults.standard.set(true, forKey: "didSetupPreferences")
    UserDefaults.standard.set(true, forKey: "metric")
    UserDefaults.standard.set(true, forKey: "displayingMetrics")
    UserDefaults.standard.set(ColourChoice.blue.rawValue, forKey: "colour")
    UserDefaults.standard.set(true, forKey: "largeMetrics")
    UserDefaults.standard.set(SortChoice.dateDescending.rawValue, forKey: "sortingChoice")
    UserDefaults.standard.set(true, forKey: "deletionConfirmation")
    UserDefaults.standard.set(true, forKey: "deletionEnabled")
    UserDefaults.standard.set(true, forKey: "namedRoutes")
    UserDefaults.standard.set("", forKey: "selectedRoute")
    UserDefaults.standard.set(false, forKey: "autoLockDisabled")
    UserDefaults.standard.set(false, forKey: "healthSyncEnabled")
    UserDefaults.standard.set(MapTypeChoice.standard.rawValue, forKey: "mapType")
    UserDefaults.standard.set(0, forKey: "iconIndex")

    let preferences = Preferences()

    #expect(preferences.autoPauseEnabled == true)
    #expect(preferences.telemetryEnabled == true)
  }

  @Test("initializes first-launch defaults when preferences were never setup")
  func initializesFirstLaunchDefaultsWhenPreferencesWereNeverSetup() async {
    let snapshot = await PersistedStoreSnapshot(keys: preferenceMutationStoreKeys)
    defer { snapshot.restore() }

    for key in preferenceMutationStoreKeys {
      UserDefaults.standard.removeObject(forKey: key)
      NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
    }
    NSUbiquitousKeyValueStore.default.synchronize()

    let preferences = Preferences()

    #expect(preferences.usingMetric == true)
    #expect(preferences.colourChoiceConverted == .blue)
    #expect(preferences.sortingChoiceConverted == .dateDescending)
    #expect(preferences.telemetryEnabled == true)
    #expect(UserDefaults.standard.bool(forKey: "didSetupPreferences") == true)
    #expect(UserDefaults.standard.bool(forKey: "metric") == true)
  }
}

private let preferenceMutationStoreKeys = [
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

private func seedPreferenceMutationDefaults() {
  UserDefaults.standard.set(true, forKey: "didSetupPreferences")
  UserDefaults.standard.set(false, forKey: iCloudSyncPreferenceKey)
  UserDefaults.standard.set(true, forKey: "metric")
  UserDefaults.standard.set(true, forKey: "displayingMetrics")
  UserDefaults.standard.set(ColourChoice.blue.rawValue, forKey: "colour")
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
