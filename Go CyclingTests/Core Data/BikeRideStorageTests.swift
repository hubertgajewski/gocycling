//
//  BikeRideStorageTests.swift
//  Go CyclingTests
//

import CoreData
import Foundation
import Testing

@testable import Go_Cycling

@Suite("BikeRideStorage", .serialized)
@MainActor
struct BikeRideStorageTests {

  @Test("loads stored rides and updates when the fetch results change")
  func loadsStoredRidesAndUpdatesWhenFetchResultsChange() async throws {
    let snapshot = await PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let persistence = PersistenceController(inMemory: true)
    let context = persistence.container.viewContext
    let first = makeStorageRide(in: context, name: "Morning", distance: 1_000)
    try context.save()

    let storage = BikeRideStorage(managedObjectContext: context)
    #expect(storage.storedBikeRides.count == 1)
    #expect(storage.storedBikeRides.first?.objectID == first.objectID)

    _ = makeStorageRide(in: context, name: "Evening", distance: 2_000)
    try context.save()

    await Task.yield()
    await Task.yield()

    #expect(storage.storedBikeRides.count == 2)
    #expect(Set(storage.storedBikeRides.map(\.cyclingRouteName)) == ["Morning", "Evening"])
  }
}

private func makeStorageRide(
  in context: NSManagedObjectContext,
  name: String,
  distance: Double
) -> BikeRide {
  let ride = BikeRide(context: context)
  ride.cyclingRouteName = name
  ride.cyclingDistance = distance
  ride.cyclingStartTime = Date(timeIntervalSince1970: distance)
  ride.cyclingTime = distance / 10
  ride.cyclingSpeeds = [4]
  ride.cyclingLatitudes = [51.5]
  ride.cyclingLongitudes = [-0.1]
  ride.cyclingElevations = [12]
  return ride
}
