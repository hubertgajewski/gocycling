//
//  RecordsTests.swift
//  Go CyclingTests
//

import CoreData
import CoreLocation
import Foundation
import Testing

@testable import Go_Cycling

@Suite("Records", .serialized)
@MainActor
struct RecordsTests {

  @Test("calculates default records from saved rides")
  func calculatesDefaultRecordsFromBikeRides() {
    let snapshot = PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let context = PersistenceController(inMemory: true).container.viewContext
    let longestDistanceDate = date(2026, 6, 10)
    let fastestAverageSpeedDate = date(2026, 6, 11)
    let longestTimeDate = date(2026, 6, 12)
    let rides = [
      makeRide(
        in: context,
        distance: 5_000,
        start: longestDistanceDate,
        time: 1_000,
        speeds: [4]
      ),
      makeRide(
        in: context,
        distance: 3_600,
        start: fastestAverageSpeedDate,
        time: 600,
        speeds: [7]
      ),
      makeRide(
        in: context,
        distance: 500,
        start: longestTimeDate,
        time: 2_000,
        speeds: [100]
      ),
    ]

    let values = Records.getDefaultRecordsValues(bikeRides: rides)

    #expect(values.totalDistance == 9_100)
    #expect(values.totalTime == 3_600)
    #expect(values.totalRoutes == 3)
    #expect(values.unlockedIcons == [false, false, false, false, false, false])
    #expect(values.longestDistance == 5_000)
    #expect(values.longestTime == 2_000)
    #expect(values.fastestAvgSpeed == 6)
    #expect(values.longestDistanceDate == longestDistanceDate)
    #expect(values.longestTimeDate == longestTimeDate)
    #expect(values.fastestAvgSpeedDate == fastestAverageSpeedDate)
  }

  @Test("ignores invalid fastest average speed candidates")
  func ignoresInvalidFastestAverageSpeedCandidates() {
    let snapshot = PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let context = PersistenceController(inMemory: true).container.viewContext
    let shortRide = makeRide(
      in: context,
      distance: 999,
      start: date(2026, 6, 13),
      time: 60,
      speeds: [100]
    )
    let impossibleAverageRide = makeRide(
      in: context,
      distance: 10_000,
      start: date(2026, 6, 14),
      time: 100,
      speeds: [3]
    )

    let values = Records.getDefaultRecordsValues(bikeRides: [shortRide, impossibleAverageRide])

    #expect(values.fastestAvgSpeed == 0)
    #expect(values.fastestAvgSpeedDate == nil)
  }

  @Test("calculates broken records from a completed ride")
  func calculatesBrokenRecordsFromCompletedRide() {
    let snapshot = PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let context = PersistenceController(inMemory: true).container.viewContext
    let oldDistanceDate = date(2026, 5, 1)
    let oldTimeDate = date(2026, 5, 2)
    let oldSpeedDate = date(2026, 5, 3)
    let newRecordDate = date(2026, 6, 15)
    let existingRecords = makeRecords(
      in: context,
      totalDistance: 10_000,
      totalTime: 2_000,
      totalRoutes: 2,
      unlockedIcons: [false, true, false, false, false, false],
      longestDistance: 4_000,
      longestTime: 1_000,
      fastestAverageSpeed: 5,
      longestDistanceDate: oldDistanceDate,
      longestTimeDate: oldTimeDate,
      fastestAverageSpeedDate: oldSpeedDate
    )

    let values = Records.getBrokenRecords(
      existingRecords: existingRecords,
      speeds: [nil, 7],
      distance: 6_000,
      startTime: newRecordDate,
      time: 1_000
    )

    #expect(values.totalDistance == 16_000)
    #expect(values.totalTime == 3_000)
    #expect(values.totalRoutes == 3)
    #expect(values.unlockedIcons == [false, true, false, false, false, false])
    #expect(values.longestDistance == 6_000)
    #expect(values.longestTime == 1_000)
    #expect(values.fastestAvgSpeed == 6)
    #expect(values.longestDistanceDate == newRecordDate)
    #expect(values.longestTimeDate == oldTimeDate)
    #expect(values.fastestAvgSpeedDate == newRecordDate)
  }

  @Test("preserves existing records when a ride does not break them")
  func preservesExistingRecordsWhenRideDoesNotBreakThem() {
    let snapshot = PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let context = PersistenceController(inMemory: true).container.viewContext
    let oldDistanceDate = date(2026, 5, 1)
    let oldTimeDate = date(2026, 5, 2)
    let oldSpeedDate = date(2026, 5, 3)
    let existingRecords = makeRecords(
      in: context,
      totalDistance: 10_000,
      totalTime: 2_000,
      totalRoutes: 2,
      unlockedIcons: [false, true, false, false, false, false],
      longestDistance: 4_000,
      longestTime: 1_000,
      fastestAverageSpeed: 5,
      longestDistanceDate: oldDistanceDate,
      longestTimeDate: oldTimeDate,
      fastestAverageSpeedDate: oldSpeedDate
    )

    let values = Records.getBrokenRecords(
      existingRecords: existingRecords,
      speeds: [nil, 10],
      distance: 3_000,
      startTime: date(2026, 6, 16),
      time: 900
    )

    #expect(values.totalDistance == 13_000)
    #expect(values.totalTime == 2_900)
    #expect(values.totalRoutes == 3)
    #expect(values.longestDistance == 4_000)
    #expect(values.longestTime == 1_000)
    #expect(values.fastestAvgSpeed == 5)
    #expect(values.longestDistanceDate == oldDistanceDate)
    #expect(values.longestTimeDate == oldTimeDate)
    #expect(values.fastestAvgSpeedDate == oldSpeedDate)
  }

  @Test("ignores missing speeds for fastest average speed")
  func ignoresMissingSpeedsForFastestAverageSpeed() {
    let snapshot = PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let context = PersistenceController(inMemory: true).container.viewContext
    let oldSpeedDate = date(2026, 5, 3)
    let existingRecords = makeRecords(
      in: context,
      totalDistance: 10_000,
      totalTime: 2_000,
      totalRoutes: 2,
      unlockedIcons: [false, true, false, false, false, false],
      longestDistance: 4_000,
      longestTime: 1_000,
      fastestAverageSpeed: 5,
      longestDistanceDate: date(2026, 5, 1),
      longestTimeDate: date(2026, 5, 2),
      fastestAverageSpeedDate: oldSpeedDate
    )

    let values = Records.getBrokenRecords(
      existingRecords: existingRecords,
      speeds: [nil, nil],
      distance: 3_000,
      startTime: date(2026, 6, 17),
      time: 300
    )

    #expect(values.fastestAvgSpeed == 5)
    #expect(values.fastestAvgSpeedDate == oldSpeedDate)
  }

  @Test("unlocks icons from individual and total distance thresholds")
  func unlocksIconsFromDistanceThresholds() {
    let snapshot = PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let context = PersistenceController(inMemory: true).container.viewContext
    let records = makeRecords(
      in: context,
      totalDistance: 250_000,
      totalTime: 2_000,
      totalRoutes: 2,
      unlockedIcons: [false, false, true, false, false, false],
      longestDistance: 25_000,
      longestTime: 1_000,
      fastestAverageSpeed: 5,
      longestDistanceDate: date(2026, 5, 1),
      longestTimeDate: date(2026, 5, 2),
      fastestAverageSpeedDate: date(2026, 5, 3)
    )

    records.setUnlockedIcons()

    #expect(records.unlockedIcons == [true, true, true, true, true, false])
  }
}

private func makeRide(
  in context: NSManagedObjectContext,
  distance: Double,
  start: Date,
  time: Double,
  speeds: [CLLocationSpeed]
) -> BikeRide {
  let entity = NSEntityDescription.entity(forEntityName: "BikeRide", in: context)!
  let ride = BikeRide(entity: entity, insertInto: context)
  ride.cyclingRouteName = "Test ride"
  ride.cyclingDistance = distance
  ride.cyclingStartTime = start
  ride.cyclingTime = time
  ride.cyclingSpeeds = speeds
  ride.cyclingLatitudes = []
  ride.cyclingLongitudes = []
  ride.cyclingElevations = []
  return ride
}

private func makeRecords(
  in context: NSManagedObjectContext,
  totalDistance: Double,
  totalTime: Double,
  totalRoutes: Int64,
  unlockedIcons: [Bool],
  longestDistance: Double,
  longestTime: Double,
  fastestAverageSpeed: Double,
  longestDistanceDate: Date?,
  longestTimeDate: Date?,
  fastestAverageSpeedDate: Date?
) -> Records {
  let entity = NSEntityDescription.entity(forEntityName: "Records", in: context)!
  let records = Records(entity: entity, insertInto: context)
  records.totalCyclingDistance = totalDistance
  records.totalCyclingTime = totalTime
  records.totalCyclingRoutes = totalRoutes
  records.unlockedIcons = unlockedIcons
  records.longestCyclingDistance = longestDistance
  records.longestCyclingTime = longestTime
  records.fastestAverageSpeed = fastestAverageSpeed
  records.longestCyclingDistanceDate = longestDistanceDate
  records.longestCyclingTimeDate = longestTimeDate
  records.fastestAverageSpeedDate = fastestAverageSpeedDate
  return records
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
