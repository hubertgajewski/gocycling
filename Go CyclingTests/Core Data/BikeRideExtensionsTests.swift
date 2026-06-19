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

    let persistence = makeInMemoryChartPersistence()
    let context = persistence.container.viewContext
    _ = makeChartRide(
      in: context, distance: 10, time: 600, start: extensionDate(2026, 6, 15), name: "Commute")
    _ = makeChartRide(
      in: context, distance: 5, time: 300, start: extensionDate(2026, 6, 16), name: "commute")
    _ = makeChartRide(
      in: context, distance: 20, time: 900, start: extensionDate(2026, 6, 17), name: "Training")
    _ = makeChartRide(
      in: context, distance: 1, time: 60, start: extensionDate(2026, 6, 18), name: "Uncategorized")
    try context.save()

    let rides = BikeRide.allBikeRides(in: context)
    let names = BikeRide.allRouteNames(from: rides)
    #expect(Set(names) == Set(["Commute", "commute", "Training"]))
    #expect(names == names.sorted { $0.lowercased() < $1.lowercased() })

    let categories = BikeRide.allCategories(from: rides)
    #expect(categories.first?.name == "All")
    #expect(categories.first?.number == 4)
    #expect(categories.contains { $0.name == "Uncategorized" && $0.number == 1 })
    #expect(categories.contains { $0.name == "Commute" && $0.number == 1 })
    #expect(categories.contains { $0.name == "Training" && $0.number == 1 })
    #expect(categories.contains { $0.name == "commute" && $0.number == 1 })
  }

  @Test("returns empty route and category lists when no rides exist")
  func returnsEmptyRouteAndCategoryListsWhenNoRidesExist() async {
    let snapshot = await PersistedStoreSnapshot(keys: extensionStoreKeys)
    defer { snapshot.restore() }
    seedExtensionPreferences()

    let persistence = makeInMemoryChartPersistence()
    let rides = BikeRide.allBikeRides(in: persistence.container.viewContext)

    #expect(rides.isEmpty)
    #expect(BikeRide.allRouteNames(from: rides).isEmpty)
    #expect(BikeRide.allCategories(from: rides).isEmpty)
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

    let persistence = makeInMemoryChartPersistence()
    let context = persistence.container.viewContext
    let short = makeChartRide(
      in: context,
      distance: 1_000,
      time: 600,
      start: extensionDate(2026, 6, 15),
      name: "short"
    )
    let long = makeChartRide(
      in: context,
      distance: 3_000,
      time: 1_200,
      start: extensionDate(2026, 6, 17),
      name: "long"
    )
    try context.save()

    let rides = BikeRide.allBikeRides(in: context)
    let sorted = BikeRide.allBikeRidesSorted(from: rides)
    #expect(sorted.map(\.cyclingRouteName) == ["short", "long"])
    #expect(sorted.first?.objectID == short.objectID)
    #expect(sorted.last?.objectID == long.objectID)
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

private func extensionDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
  var components = DateComponents()
  components.calendar = Calendar(identifier: .gregorian)
  components.timeZone = TimeZone(secondsFromGMT: 0)
  components.year = year
  components.month = month
  components.day = day
  return components.date!
}
