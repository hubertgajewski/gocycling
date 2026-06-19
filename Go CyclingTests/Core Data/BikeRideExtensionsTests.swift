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

    let persistence = PersistenceController.shared
    defer { persistence.deleteAllBikeRides() }
    persistence.deleteAllBikeRides()

    let context = persistence.container.viewContext
    _ = makeExtensionRide(
      in: context,
      name: "Commute",
      distance: 10,
      start: extensionDate(2026, 6, 15),
      time: 600
    )
    _ = makeExtensionRide(
      in: context,
      name: "commute",
      distance: 5,
      start: extensionDate(2026, 6, 16),
      time: 300
    )
    _ = makeExtensionRide(
      in: context,
      name: "Training",
      distance: 20,
      start: extensionDate(2026, 6, 17),
      time: 900
    )
    _ = makeExtensionRide(
      in: context,
      name: "Uncategorized",
      distance: 1,
      start: extensionDate(2026, 6, 18),
      time: 60
    )
    try context.save()

    let names = BikeRide.allRouteNames()
    #expect(Set(names) == Set(["Commute", "commute", "Training"]))
    #expect(names == names.sorted { $0.lowercased() < $1.lowercased() })

    let categories = BikeRide.allCategories()
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

    let persistence = PersistenceController.shared
    defer { persistence.deleteAllBikeRides() }
    persistence.deleteAllBikeRides()

    #expect(BikeRide.allRouteNames().isEmpty)
    #expect(BikeRide.allCategories().isEmpty)
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

    let persistence = PersistenceController.shared
    defer { persistence.deleteAllBikeRides() }
    persistence.deleteAllBikeRides()

    let context = persistence.container.viewContext
    let short = makeExtensionRide(
      in: context,
      name: "short",
      distance: 1_000,
      start: extensionDate(2026, 6, 15),
      time: 600
    )
    let long = makeExtensionRide(
      in: context,
      name: "long",
      distance: 3_000,
      start: extensionDate(2026, 6, 17),
      time: 1_200
    )
    try context.save()

    let sorted = BikeRide.allBikeRidesSorted()
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

private func makeExtensionRide(
  in context: NSManagedObjectContext,
  name: String,
  distance: Double,
  start: Date,
  time: Double
) -> BikeRide {
  let ride = BikeRide(context: context)
  ride.cyclingRouteName = name
  ride.cyclingDistance = distance
  ride.cyclingStartTime = start
  ride.cyclingTime = time
  ride.cyclingSpeeds = [5]
  ride.cyclingLatitudes = [51.5]
  ride.cyclingLongitudes = [-0.1]
  ride.cyclingElevations = [10]
  return ride
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
