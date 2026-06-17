//
//  PreferencesConversionTests.swift
//  Go CyclingTests
//

import CoreData
import Foundation
import MapKit
import Testing
import UIKit

@testable import Go_Cycling

@Suite("Preferences conversion", .serialized)
@MainActor
struct PreferencesConversionTests {

  @Test("converts stored preference values to display enums")
  func convertsStoredPreferenceValuesToEnums() {
    let snapshot = PersistedStoreSnapshot(keys: preferenceStoreKeys)
    defer { snapshot.restore() }
    seedPreferenceDefaults()

    let preferences = Preferences()
    preferences.colourChoice = ColourChoice.green.rawValue
    preferences.sortingChoice = SortChoice.timeAscending.rawValue
    preferences.usingMetric = false
    preferences.mapTypeChoice = MapTypeChoice.hybrid.rawValue

    #expect(preferences.colourChoiceConverted == .green)
    #expect(preferences.sortingChoiceConverted == .timeAscending)
    #expect(preferences.metricsChoiceConverted == .imperial)
    #expect(preferences.mapTypeChoiceConverted == .hybrid)
  }

  @Test("falls back for invalid stored preference values")
  func fallsBackForInvalidStoredPreferenceValues() {
    let snapshot = PersistedStoreSnapshot(keys: preferenceStoreKeys)
    defer { snapshot.restore() }
    seedPreferenceDefaults()

    let preferences = Preferences()
    preferences.colourChoice = "not-a-colour"
    preferences.sortingChoice = "not-a-sort"
    preferences.mapTypeChoice = "not-a-map"

    #expect(preferences.colourChoiceConverted == .blue)
    #expect(preferences.sortingChoiceConverted == .dateDescending)
    #expect(preferences.mapTypeChoiceConverted == .standard)
  }

  @Test("reads stored sort and selected route preferences")
  func readsStoredSortAndSelectedRoutePreferences() {
    let snapshot = PersistedStoreSnapshot(keys: preferenceStoreKeys)
    defer { snapshot.restore() }
    seedPreferenceDefaults()

    UserDefaults.standard.set(SortChoice.distanceAscending.rawValue, forKey: "sortingChoice")
    UserDefaults.standard.set("Commute", forKey: "selectedRoute")
    #expect(Preferences.storedSortingChoice() == .distanceAscending)
    #expect(Preferences.storedSelectedRoute() == "Commute")

    UserDefaults.standard.set("not-a-sort", forKey: "sortingChoice")
    #expect(Preferences.storedSortingChoice() == .dateDescending)
  }

  @Test("converts legacy user preferences values")
  func convertsLegacyUserPreferencesValues() {
    let snapshot = PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let context = PersistenceController(inMemory: true).container.viewContext
    let entity = NSEntityDescription.entity(forEntityName: "UserPreferences", in: context)!
    let preferences = UserPreferences(entity: entity, insertInto: context)
    preferences.colourChoice = ColourChoice.orange.rawValue
    preferences.sortingChoice = SortChoice.dateAscending.rawValue
    preferences.usingMetric = true

    #expect(UserPreferences.convertColourChoiceToUIColor(colour: .red).isEqual(UIColor.systemRed))
    #expect(
      UserPreferences.convertColourChoiceToUIColor(colour: .violet).isEqual(UIColor.systemPurple))
    #expect(preferences.colourChoiceConverted == .orange)
    #expect(preferences.sortingChoiceConverted == .dateAscending)
    #expect(preferences.metricsChoiceConverted == .metric)

    preferences.colourChoiceConverted = .indigo
    preferences.sortingChoiceConverted = .timeDescending
    preferences.metricsChoiceConverted = .imperial

    #expect(preferences.colourChoice == ColourChoice.indigo.rawValue)
    #expect(preferences.sortingChoice == SortChoice.timeDescending.rawValue)
    #expect(preferences.usingMetric == false)
  }

  @Test("maps map type choices to MapKit values")
  func mapsMapTypeChoicesToMapKitValues() {
    #expect(MapTypeChoice.standard.mkMapType == .standard)
    #expect(MapTypeChoice.satellite.mkMapType == .satellite)
    #expect(MapTypeChoice.hybrid.mkMapType == .hybrid)
  }
}

private let preferenceStoreKeys = [
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
  "iCloudOn",
  "telemetryEnabled",
]

private func seedPreferenceDefaults() {
  UserDefaults.standard.set(true, forKey: "didSetupPreferences")
  UserDefaults.standard.set(false, forKey: "iCloudOn")
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
  UserDefaults.standard.set(true, forKey: "telemetryEnabled")
}
