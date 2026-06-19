//
//  BikeRideExtensionsTests.swift
//  Go CyclingTests
//

import CoreData
import Foundation
import Testing

@testable import Go_Cycling

@Suite("BikeRide extensions", .serialized)
@MainActor
struct BikeRideExtensionsTests {

  @Test("builds sorted route names and category counts")
  func buildsSortedRouteNamesAndCategories() async throws {
    let snapshot = await PersistedStoreSnapshot(keys: extensionStoreKeys)
    defer { snapshot.restore() }
    seedExtensionPreferences()

    let fixture = SharedStoreRideFixture()
    defer { fixture.cleanup() }

    _ = fixture.insert(
      name: "Issue41-Commute",
      distance: 10,
      start: fixtureDate(2026, 6, 15),
      time: 600
    )
    _ = fixture.insert(
      name: "Issue41-commute",
      distance: 5,
      start: fixtureDate(2026, 6, 16),
      time: 300
    )
    _ = fixture.insert(
      name: "Issue41-Training",
      distance: 20,
      start: fixtureDate(2026, 6, 17),
      time: 900
    )
    _ = fixture.insert(
      name: "Uncategorized",
      distance: 1,
      start: fixtureDate(2026, 6, 18),
      time: 60
    )
    try fixture.save()

    let names = BikeRide.allRouteNames().filter { $0.hasPrefix("Issue41-") }
    #expect(Set(names) == Set(["Issue41-Commute", "Issue41-commute", "Issue41-Training"]))
    #expect(names == names.sorted { $0.lowercased() < $1.lowercased() })

    let categories = BikeRide.allCategories()
    #expect(categories.first?.name == "All")
    #expect(categories.contains { $0.name == "Issue41-Commute" && $0.number == 1 })
    #expect(categories.contains { $0.name == "Issue41-commute" && $0.number == 1 })
    #expect(categories.contains { $0.name == "Issue41-Training" && $0.number == 1 })
  }

  @Test("sorts all bike rides using the stored preference")
  func sortsAllBikeRidesUsingStoredPreference() async throws {
    let snapshot = await PersistedStoreSnapshot(keys: extensionStoreKeys)
    defer { snapshot.restore() }
    seedExtensionPreferences()

    Preferences.shared.updateStringPreference(
      preference: .sortingChoice,
      value: SortChoice.distanceAscending.rawValue
    )

    let fixture = SharedStoreRideFixture()
    defer { fixture.cleanup() }

    let short = fixture.insert(
      name: "Issue41-short",
      distance: 1_000,
      start: fixtureDate(2026, 6, 15),
      time: 600
    )
    let long = fixture.insert(
      name: "Issue41-long",
      distance: 3_000,
      start: fixtureDate(2026, 6, 17),
      time: 1_200
    )
    try fixture.save()

    let sorted = BikeRide.allBikeRidesSorted().filter {
      $0.objectID == short.objectID || $0.objectID == long.objectID
    }
    #expect(sorted.map(\.cyclingRouteName) == ["Issue41-short", "Issue41-long"])
  }
}

private let extensionStoreKeys = [
  iCloudSyncPreferenceKey,
  "didSetupPreferences",
  "sortingChoice",
]

private func seedExtensionPreferences() {
  UserDefaults.standard.set(false, forKey: iCloudSyncPreferenceKey)
  UserDefaults.standard.set(true, forKey: "didSetupPreferences")
  UserDefaults.standard.set(SortChoice.dateDescending.rawValue, forKey: "sortingChoice")
}
