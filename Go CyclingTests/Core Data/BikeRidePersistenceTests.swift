//
//  BikeRidePersistenceTests.swift
//  Go CyclingTests
//

import CoreData
import CoreLocation
import Foundation
import Testing

@testable import Go_Cycling

@Suite("Bike ride persistence", .serialized)
@MainActor
struct BikeRidePersistenceTests {

  @Test("stores ride data in an in-memory store")
  func storesRideData() async throws {
    let snapshot = await PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let persistence = makeInMemoryPersistenceController()
    let startTime = Date(timeIntervalSince1970: 1_800)

    var saveResult: Result<BikeRide, Error>?
    await withCheckedContinuation { continuation in
      persistence.storeBikeRide(
        locations: [
          CLLocation(latitude: 51.5, longitude: -0.12),
          nil,
          CLLocation(latitude: 52.0, longitude: -0.2),
        ],
        speeds: [4.2, nil, 5.5],
        distance: 1_200,
        elevations: [15, nil, 21],
        startTime: startTime,
        time: 360
      ) { result in
        saveResult = result
        continuation.resume()
      }
    }
    guard case .success(let savedRide) = saveResult else {
      Issue.record("Expected bike ride save to succeed")
      return
    }

    let rides = try fetchRides(in: persistence.container.viewContext)

    #expect(rides.count == 1)
    let ride = try #require(rides.first)
    #expect(ride.cyclingLatitudes == [51.5, 52.0])
    #expect(ride.cyclingLongitudes == [-0.12, -0.2])
    #expect(ride.cyclingSpeeds == [4.2, 5.5])
    #expect(ride.cyclingDistance == 1_200)
    #expect(ride.cyclingElevations == [15, 21])
    #expect(ride.cyclingStartTime == startTime)
    #expect(ride.cyclingTime == 360)
    #expect(ride.cyclingRouteName == "Uncategorized")
    #expect(savedRide.objectID == ride.objectID)
  }

  @Test("renames matching categories and leaves other rides unchanged")
  func renamesMatchingCategoriesAndLeavesOtherRidesUnchanged() async throws {
    let snapshot = await PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let persistence = makeInMemoryPersistenceController()
    let context = persistence.container.viewContext
    makeRide(in: context, name: "Commute", distance: 1_000)
    makeRide(in: context, name: "Commute", distance: 1_500)
    makeRide(in: context, name: "Training", distance: 2_000)
    let untouched = makeRide(in: context, name: "Errands", distance: 750)
    try context.save()

    persistence.updateBikeRideCategories(
      oldCategoriesToUpdate: ["Commute", "Training"],
      newCategoryNames: ["Work", "Workout"]
    )

    let rides = try fetchRides(in: context)
    #expect(countsByRouteName(rides) == ["Work": 2, "Workout": 1, "Errands": 1])
    #expect(untouched.cyclingRouteName == "Errands")
    #expect(untouched.cyclingDistance == 750)
  }

  @Test("does not rename categories when inputs do not pair cleanly")
  func doesNotRenameCategoriesWhenInputsDoNotPairCleanly() async throws {
    let snapshot = await PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let persistence = makeInMemoryPersistenceController()
    let context = persistence.container.viewContext
    makeRide(in: context, name: "Commute", distance: 1_000)
    makeRide(in: context, name: "Training", distance: 2_000)
    try context.save()

    persistence.updateBikeRideCategories(
      oldCategoriesToUpdate: ["Commute", "Training"],
      newCategoryNames: ["Work"]
    )
    persistence.updateBikeRideCategories(
      oldCategoriesToUpdate: ["Commute"],
      newCategoryNames: []
    )

    #expect(countsByRouteName(try fetchRides(in: context)) == ["Commute": 1, "Training": 1])
  }

  @Test("removes only matching category rides")
  func removesOnlyMatchingCategoryRides() async throws {
    let snapshot = await PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let persistence = makeInMemoryPersistenceController()
    let context = persistence.container.viewContext
    makeRide(in: context, name: "Commute", distance: 1_000)
    makeRide(in: context, name: "Commute", distance: 1_500)
    let untouched = makeRide(in: context, name: "Training", distance: 2_000)
    try context.save()

    persistence.removeCategory(categoryName: "Commute")

    #expect(countsByRouteName(try fetchRides(in: context)) == ["Uncategorized": 2, "Training": 1])
    #expect(untouched.cyclingRouteName == "Training")
    #expect(untouched.cyclingDistance == 2_000)
  }

  @Test("deletes all saved rides")
  func deletesAllSavedRides() async throws {
    let snapshot = await PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let persistence = makeInMemoryPersistenceController()
    let context = persistence.container.viewContext
    makeRide(in: context, name: "Commute", distance: 1_000)
    makeRide(in: context, name: "Training", distance: 2_000)
    makeRide(in: context, name: "Uncategorized", distance: 500)
    try context.save()

    persistence.deleteAllBikeRides()

    #expect(try fetchRides(in: context).isEmpty)
  }

  @Test("route save fixture uses an isolated non-CloudKit store")
  func routeSaveFixtureUsesIsolatedNonCloudKitStore() throws {
    let suiteName = "GoCyclingTests.RouteSaveFixture.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set(true, forKey: iCloudSyncPreferenceKey)
    let description = NSPersistentStoreDescription()
    description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
      containerIdentifier: "iCloud.test.GoCycling"
    )
    let isolatedURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("GoCyclingTests-\(UUID().uuidString).sqlite")

    #if DEBUG
      let configured = PersistenceController.configureStoreForUITestingIfNeeded(
        description,
        arguments: UITesting.routeSaveFixtureLaunchArguments,
        storeURL: isolatedURL
      )

      #expect(configured)
      #expect(description.url == isolatedURL)
      #expect(description.cloudKitContainerOptions == nil)
      #expect(defaults.bool(forKey: iCloudSyncPreferenceKey) == true)
      #expect(
        defaults.persistentDomain(forName: suiteName)?[iCloudSyncPreferenceKey] as? Bool == true)
    #else
      #expect(Bool(true))
    #endif
  }
}

private func makeInMemoryPersistenceController() -> PersistenceController {
  UserDefaults.standard.set(false, forKey: iCloudSyncPreferenceKey)
  return PersistenceController(inMemory: true)
}

@discardableResult
private func makeRide(
  in context: NSManagedObjectContext,
  name: String,
  distance: Double
) -> BikeRide {
  let ride = BikeRide(context: context)
  ride.cyclingRouteName = name
  ride.cyclingDistance = distance
  ride.cyclingStartTime = Date(timeIntervalSince1970: distance)
  ride.cyclingTime = distance / 10
  ride.cyclingSpeeds = [3]
  ride.cyclingLatitudes = [51]
  ride.cyclingLongitudes = [-0.1]
  ride.cyclingElevations = [20]
  return ride
}

private func fetchRides(in context: NSManagedObjectContext) throws -> [BikeRide] {
  let request: NSFetchRequest<BikeRide> = BikeRide.fetchRequest()
  request.sortDescriptors = [
    NSSortDescriptor(keyPath: \BikeRide.cyclingRouteName, ascending: true),
    NSSortDescriptor(keyPath: \BikeRide.cyclingDistance, ascending: true),
  ]
  return try context.fetch(request)
}

private func countsByRouteName(_ rides: [BikeRide]) -> [String: Int] {
  Dictionary(grouping: rides, by: \.cyclingRouteName).mapValues(\.count)
}
