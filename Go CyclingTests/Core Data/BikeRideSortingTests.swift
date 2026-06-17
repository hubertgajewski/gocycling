//
//  BikeRideSortingTests.swift
//  Go CyclingTests
//

import CoreData
import CoreLocation
import Foundation
import Testing

@testable import Go_Cycling

@Suite("BikeRide sorting", .serialized)
@MainActor
struct BikeRideSortingTests {

  @Test("sorts rides by distance, date, and time")
  func sortsRidesByDistanceDateAndTime() throws {
    let snapshot = PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let context = PersistenceController(inMemory: true).container.viewContext
    let oldest = makeRide(
      in: context,
      name: "oldest",
      distance: 2_000,
      start: date(2026, 6, 15),
      time: 900
    )
    let newest = makeRide(
      in: context,
      name: "newest",
      distance: 3_000,
      start: date(2026, 6, 17),
      time: 1_200
    )
    let middle = makeRide(
      in: context,
      name: "middle",
      distance: 1_000,
      start: date(2026, 6, 16),
      time: 600
    )
    let rides = [oldest, newest, middle]
    let distanceAscending = BikeRide.sortByDistance(list: rides, ascending: true)
    let distanceDescending = BikeRide.sortByDistance(list: rides, ascending: false)
    let dateAscending = BikeRide.sortByDate(list: rides, ascending: true)
    let dateDescending = BikeRide.sortByDate(list: rides, ascending: false)
    let timeAscending = BikeRide.sortByTime(list: rides, ascending: true)
    let timeDescending = BikeRide.sortByTime(list: rides, ascending: false)

    #expect(distanceAscending.map(\.cyclingRouteName) == ["middle", "oldest", "newest"])
    #expect(distanceDescending.map(\.cyclingRouteName) == ["newest", "oldest", "middle"])
    #expect(dateAscending.map(\.cyclingRouteName) == ["oldest", "middle", "newest"])
    #expect(dateDescending.map(\.cyclingRouteName) == ["newest", "middle", "oldest"])
    #expect(timeAscending.map(\.cyclingRouteName) == ["middle", "oldest", "newest"])
    #expect(timeDescending.map(\.cyclingRouteName) == ["newest", "oldest", "middle"])
    for sortedRides in [
      distanceAscending, distanceDescending, dateAscending, dateDescending, timeAscending,
      timeDescending,
    ] {
      #expect(
        Set(sortedRides.map { ObjectIdentifier($0) }) == Set(rides.map { ObjectIdentifier($0) }))
    }
  }

  @Test("keeps empty and single-item lists stable")
  func keepsEdgeCaseListsStable() {
    let snapshot = PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let empty: [BikeRide] = []
    #expect(BikeRide.sortByDistance(list: empty, ascending: true).isEmpty)
    #expect(BikeRide.sortByDate(list: empty, ascending: false).isEmpty)
    #expect(BikeRide.sortByTime(list: empty, ascending: true).isEmpty)

    let context = PersistenceController(inMemory: true).container.viewContext
    let solo = makeRide(
      in: context,
      name: "solo",
      distance: 4_200,
      start: date(2026, 6, 18),
      time: 1_500
    )

    #expect(
      BikeRide.sortByDistance(list: [solo], ascending: false).map(\.cyclingRouteName) == ["solo"])
    #expect(BikeRide.sortByDate(list: [solo], ascending: true).map(\.cyclingRouteName) == ["solo"])
    #expect(BikeRide.sortByTime(list: [solo], ascending: false).map(\.cyclingRouteName) == ["solo"])
  }
}

private func makeRide(
  in context: NSManagedObjectContext,
  name: String,
  distance: Double,
  start: Date,
  time: Double,
  speeds: [CLLocationSpeed] = [10]
) -> BikeRide {
  let entity = NSEntityDescription.entity(forEntityName: "BikeRide", in: context)!
  let ride = BikeRide(entity: entity, insertInto: context)
  ride.cyclingRouteName = name
  ride.cyclingDistance = distance
  ride.cyclingStartTime = start
  ride.cyclingTime = time
  ride.cyclingSpeeds = speeds
  ride.cyclingLatitudes = []
  ride.cyclingLongitudes = []
  ride.cyclingElevations = []
  return ride
}

private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
  var components = DateComponents()
  components.calendar = Calendar(identifier: .gregorian)
  components.timeZone = TimeZone(secondsFromGMT: 0)
  components.year = year
  components.month = month
  components.day = day
  return components.date!
}
