//
//  CyclingRecordsTests.swift
//  Go CyclingTests
//

import CoreLocation
import Foundation
import Testing

@testable import Go_Cycling

@Suite("CyclingRecords", .serialized)
struct CyclingRecordsTests {

  @Test("updates cycling records and persists local and iCloud values")
  @MainActor
  func updatesCyclingRecordsAndPersistedStores() {
    let snapshot = PersistedStoreSnapshot(keys: cyclingRecordStoreKeys + [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }
    let assertICloud = ubiquitousStorePersistsValues()

    let startTime = date(2026, 6, 17)
    seedRecordStores(
      totalTime: 1_000,
      totalDistance: 10_000,
      unlockedIcons: [false, false, false, false, false, false],
      longestDistance: 8_000,
      longestTime: 900,
      fastestAverageSpeed: 5,
      fastestAverageSpeedDate: date(2026, 5, 1),
      longestDistanceDate: date(2026, 5, 2),
      longestTimeDate: date(2026, 5, 3),
      totalRoutes: 2
    )
    let records = CyclingRecords()

    records.updateCyclingRecords(
      speeds: [nil, 11],
      distance: 12_000,
      startTime: startTime,
      time: 1_200
    )

    #expect(records.totalCyclingDistance == 22_000)
    #expect(records.totalCyclingTime == 2_200)
    #expect(records.totalCyclingRoutes == 3)
    #expect(records.longestCyclingDistance == 12_000)
    #expect(records.longestCyclingTime == 1_200)
    #expect(records.fastestAverageSpeed == 10)
    #expect(records.longestCyclingDistanceDate == startTime)
    #expect(records.longestCyclingTimeDate == startTime)
    #expect(records.fastestAverageSpeedDate == startTime)
    #expect(records.unlockedIcons == [true, false, false, false, false, false])
    expectPersistedRecords(
      totalTime: 2_200,
      totalDistance: 22_000,
      unlockedIcons: [true, false, false, false, false, false],
      longestDistance: 12_000,
      longestTime: 1_200,
      fastestAverageSpeed: 10,
      fastestAverageSpeedDate: startTime,
      longestDistanceDate: startTime,
      longestTimeDate: startTime,
      totalRoutes: 3,
      assertICloud: assertICloud
    )
  }

  @Test("keeps existing personal records when a ride does not beat them")
  @MainActor
  func keepsExistingPersonalRecordsWhenRideDoesNotBeatThem() {
    let snapshot = PersistedStoreSnapshot(keys: cyclingRecordStoreKeys + [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }
    let assertICloud = ubiquitousStorePersistsValues()

    let oldDistanceDate = date(2026, 5, 2)
    let oldTimeDate = date(2026, 5, 3)
    let oldSpeedDate = date(2026, 5, 4)
    seedRecordStores(
      totalTime: 1_000,
      totalDistance: 40_000,
      unlockedIcons: [true, false, false, false, false, false],
      longestDistance: 20_000,
      longestTime: 1_800,
      fastestAverageSpeed: 12,
      fastestAverageSpeedDate: oldSpeedDate,
      longestDistanceDate: oldDistanceDate,
      longestTimeDate: oldTimeDate,
      totalRoutes: 4
    )
    let records = CyclingRecords()

    records.updateCyclingRecords(
      speeds: [12, 13],
      distance: 5_000,
      startTime: date(2026, 6, 18),
      time: 600
    )

    #expect(records.totalCyclingDistance == 45_000)
    #expect(records.totalCyclingTime == 1_600)
    #expect(records.totalCyclingRoutes == 5)
    #expect(records.longestCyclingDistance == 20_000)
    #expect(records.longestCyclingTime == 1_800)
    #expect(records.longestCyclingDistanceDate == oldDistanceDate)
    #expect(records.longestCyclingTimeDate == oldTimeDate)
    #expect(records.fastestAverageSpeed == 12)
    #expect(records.fastestAverageSpeedDate == oldSpeedDate)
    expectPersistedRecords(
      totalTime: 1_600,
      totalDistance: 45_000,
      unlockedIcons: [true, false, false, false, false, false],
      longestDistance: 20_000,
      longestTime: 1_800,
      fastestAverageSpeed: 12,
      fastestAverageSpeedDate: oldSpeedDate,
      longestDistanceDate: oldDistanceDate,
      longestTimeDate: oldTimeDate,
      totalRoutes: 5,
      assertICloud: assertICloud
    )
  }

  @Test("updates unlocked icons from individual and total distance thresholds")
  @MainActor
  func updatesUnlockedIconsFromDistanceThresholds() {
    let snapshot = PersistedStoreSnapshot(keys: cyclingRecordStoreKeys + [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }
    let assertICloud = ubiquitousStorePersistsValues()

    seedRecordStores(
      totalTime: 1_000,
      totalDistance: 500_000,
      unlockedIcons: [false, true, false, false, false, true],
      longestDistance: 50_000,
      longestTime: 900,
      fastestAverageSpeed: 5,
      fastestAverageSpeedDate: date(2026, 5, 1),
      longestDistanceDate: date(2026, 5, 2),
      longestTimeDate: date(2026, 5, 3),
      totalRoutes: 2
    )
    let records = CyclingRecords()

    records.updateUnlockedIcons()

    #expect(records.unlockedIcons == [true, true, true, true, true, true])
    #expect(
      UserDefaults.standard.array(forKey: "unlockedIcons") as? [Bool]
        == [true, true, true, true, true, true]
    )
    // TODO(#24): Replace this runtime iCloud guard with deterministic unavailable-store coverage.
    if assertICloud {
      #expect(
        NSUbiquitousKeyValueStore.default.array(forKey: "unlockedIcons") as? [Bool]
          == [true, true, true, true, true, true]
      )
    }
  }

  @Test("unlocks cumulative awards when a completed ride crosses the total threshold")
  @MainActor
  func unlocksCumulativeAwardsWhenRideCrossesTotalThreshold() {
    let snapshot = PersistedStoreSnapshot(keys: cyclingRecordStoreKeys + [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }
    let assertICloud = ubiquitousStorePersistsValues()

    let oldSpeedDate = date(2026, 5, 1)
    let oldDistanceDate = date(2026, 5, 2)
    let oldTimeDate = date(2026, 5, 3)
    seedRecordStores(
      totalTime: 1_000,
      totalDistance: 99_000,
      unlockedIcons: [false, false, false, false, false, false],
      longestDistance: 9_000,
      longestTime: 1_500,
      fastestAverageSpeed: 12,
      fastestAverageSpeedDate: oldSpeedDate,
      longestDistanceDate: oldDistanceDate,
      longestTimeDate: oldTimeDate,
      totalRoutes: 9
    )
    let records = CyclingRecords()

    records.updateCyclingRecords(
      speeds: [12],
      distance: 2_000,
      startTime: date(2026, 6, 18),
      time: 200
    )

    #expect(records.unlockedIcons == [false, false, false, true, false, false])
    expectPersistedRecords(
      totalTime: 1_200,
      totalDistance: 101_000,
      unlockedIcons: [false, false, false, true, false, false],
      longestDistance: 9_000,
      longestTime: 1_500,
      fastestAverageSpeed: 12,
      fastestAverageSpeedDate: oldSpeedDate,
      longestDistanceDate: oldDistanceDate,
      longestTimeDate: oldTimeDate,
      totalRoutes: 10,
      assertICloud: assertICloud
    )
  }

  @Test("ignores missing speeds when updating fastest average speed")
  @MainActor
  func ignoresMissingSpeedsWhenUpdatingFastestAverageSpeed() {
    let snapshot = PersistedStoreSnapshot(keys: cyclingRecordStoreKeys + [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }
    let assertICloud = ubiquitousStorePersistsValues()

    let oldSpeedDate = date(2026, 5, 1)
    seedRecordStores(
      totalTime: 1_000,
      totalDistance: 10_000,
      unlockedIcons: [false, false, false, false, false, false],
      longestDistance: 8_000,
      longestTime: 900,
      fastestAverageSpeed: 5,
      fastestAverageSpeedDate: oldSpeedDate,
      longestDistanceDate: date(2026, 5, 2),
      longestTimeDate: date(2026, 5, 3),
      totalRoutes: 2
    )
    let records = CyclingRecords()

    records.updateCyclingRecords(
      speeds: [nil, nil],
      distance: 3_000,
      startTime: date(2026, 6, 18),
      time: 300
    )

    #expect(records.fastestAverageSpeed == 5)
    #expect(records.fastestAverageSpeedDate == oldSpeedDate)
    #expect(UserDefaults.standard.double(forKey: "fastestAverageSpeed") == 5)
    #expect(
      UserDefaults.standard.object(forKey: "fastestAverageSpeedDate") as? Date == oldSpeedDate)
    // TODO(#24): Replace this runtime iCloud guard with deterministic unavailable-store coverage.
    if assertICloud {
      #expect(NSUbiquitousKeyValueStore.default.double(forKey: "fastestAverageSpeed") == 5)
      #expect(
        NSUbiquitousKeyValueStore.default.object(forKey: "fastestAverageSpeedDate") as? Date
          == oldSpeedDate)
    }
  }

  @Test("ignores sub one kilometer rides when updating fastest average speed")
  @MainActor
  func ignoresSubOneKilometerRidesWhenUpdatingFastestAverageSpeed() {
    let snapshot = PersistedStoreSnapshot(keys: cyclingRecordStoreKeys + [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }
    let assertICloud = ubiquitousStorePersistsValues()

    let oldSpeedDate = date(2026, 5, 1)
    seedRecordStores(
      totalTime: 1_000,
      totalDistance: 10_000,
      unlockedIcons: [false, false, false, false, false, false],
      longestDistance: 8_000,
      longestTime: 900,
      fastestAverageSpeed: 5,
      fastestAverageSpeedDate: oldSpeedDate,
      longestDistanceDate: date(2026, 5, 2),
      longestTimeDate: date(2026, 5, 3),
      totalRoutes: 2
    )
    let records = CyclingRecords()

    records.updateCyclingRecords(
      speeds: [20],
      distance: 999,
      startTime: date(2026, 6, 18),
      time: 50
    )

    expectFastestAverageSpeedUnchanged(
      records: records,
      fastestAverageSpeed: 5,
      fastestAverageSpeedDate: oldSpeedDate,
      assertICloud: assertICloud
    )
  }

  @Test("ignores averages faster than the sampled maximum speed")
  @MainActor
  func ignoresAveragesFasterThanSampledMaximumSpeed() {
    let snapshot = PersistedStoreSnapshot(keys: cyclingRecordStoreKeys + [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }
    let assertICloud = ubiquitousStorePersistsValues()

    let oldSpeedDate = date(2026, 5, 1)
    seedRecordStores(
      totalTime: 1_000,
      totalDistance: 10_000,
      unlockedIcons: [false, false, false, false, false, false],
      longestDistance: 8_000,
      longestTime: 900,
      fastestAverageSpeed: 5,
      fastestAverageSpeedDate: oldSpeedDate,
      longestDistanceDate: date(2026, 5, 2),
      longestTimeDate: date(2026, 5, 3),
      totalRoutes: 2
    )
    let records = CyclingRecords()

    records.updateCyclingRecords(
      speeds: [8],
      distance: 3_000,
      startTime: date(2026, 6, 18),
      time: 300
    )

    expectFastestAverageSpeedUnchanged(
      records: records,
      fastestAverageSpeed: 5,
      fastestAverageSpeedDate: oldSpeedDate,
      assertICloud: assertICloud
    )
  }

  @Test("ignores slower valid rides when updating fastest average speed")
  @MainActor
  func ignoresSlowerValidRidesWhenUpdatingFastestAverageSpeed() {
    let snapshot = PersistedStoreSnapshot(keys: cyclingRecordStoreKeys + [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }
    let assertICloud = ubiquitousStorePersistsValues()

    let oldSpeedDate = date(2026, 5, 1)
    seedRecordStores(
      totalTime: 1_000,
      totalDistance: 10_000,
      unlockedIcons: [false, false, false, false, false, false],
      longestDistance: 8_000,
      longestTime: 900,
      fastestAverageSpeed: 11,
      fastestAverageSpeedDate: oldSpeedDate,
      longestDistanceDate: date(2026, 5, 2),
      longestTimeDate: date(2026, 5, 3),
      totalRoutes: 2
    )
    let records = CyclingRecords()

    records.updateCyclingRecords(
      speeds: [10],
      distance: 3_000,
      startTime: date(2026, 6, 18),
      time: 300
    )

    expectFastestAverageSpeedUnchanged(
      records: records,
      fastestAverageSpeed: 11,
      fastestAverageSpeedDate: oldSpeedDate,
      assertICloud: assertICloud
    )
  }

  @Test("resets statistics while preserving unlocked icons")
  @MainActor
  func resetsStatisticsWhilePreservingUnlockedIcons() {
    let snapshot = PersistedStoreSnapshot(keys: cyclingRecordStoreKeys + [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }
    let assertICloud = ubiquitousStorePersistsValues()

    let unlockedIcons = [true, false, true, false, true, false]
    seedRecordStores(
      totalTime: 4_000,
      totalDistance: 75_000,
      unlockedIcons: unlockedIcons,
      longestDistance: 25_000,
      longestTime: 2_000,
      fastestAverageSpeed: 8,
      fastestAverageSpeedDate: date(2026, 5, 1),
      longestDistanceDate: date(2026, 5, 2),
      longestTimeDate: date(2026, 5, 3),
      totalRoutes: 7
    )

    CyclingRecords.resetStatistics()

    #expect(UserDefaults.standard.double(forKey: "totalCyclingTime") == 0)
    #expect(UserDefaults.standard.double(forKey: "totalCyclingDistance") == 0)
    #expect(UserDefaults.standard.double(forKey: "longestCyclingDistance") == 0)
    #expect(UserDefaults.standard.double(forKey: "longestCyclingTime") == 0)
    #expect(UserDefaults.standard.double(forKey: "fastestAverageSpeed") == 0)
    #expect(UserDefaults.standard.object(forKey: "fastestAverageSpeedDate") == nil)
    #expect(UserDefaults.standard.object(forKey: "longestCyclingDistanceDate") == nil)
    #expect(UserDefaults.standard.object(forKey: "longestCyclingTimeDate") == nil)
    #expect(UserDefaults.standard.integer(forKey: "totalCyclingRoutes") == 0)
    #expect(UserDefaults.standard.array(forKey: "unlockedIcons") as? [Bool] == unlockedIcons)

    // TODO(#24): Replace this runtime iCloud guard with deterministic unavailable-store coverage.
    if assertICloud {
      #expect(NSUbiquitousKeyValueStore.default.double(forKey: "totalCyclingTime") == 0)
      #expect(NSUbiquitousKeyValueStore.default.double(forKey: "totalCyclingDistance") == 0)
      #expect(NSUbiquitousKeyValueStore.default.double(forKey: "longestCyclingDistance") == 0)
      #expect(NSUbiquitousKeyValueStore.default.double(forKey: "longestCyclingTime") == 0)
      #expect(NSUbiquitousKeyValueStore.default.double(forKey: "fastestAverageSpeed") == 0)
      #expect(NSUbiquitousKeyValueStore.default.object(forKey: "fastestAverageSpeedDate") == nil)
      #expect(NSUbiquitousKeyValueStore.default.object(forKey: "longestCyclingDistanceDate") == nil)
      #expect(NSUbiquitousKeyValueStore.default.object(forKey: "longestCyclingTimeDate") == nil)
      #expect(NSUbiquitousKeyValueStore.default.longLong(forKey: "totalCyclingRoutes") == 0)
      #expect(
        NSUbiquitousKeyValueStore.default.array(forKey: "unlockedIcons") as? [Bool] == unlockedIcons
      )
    }

    #expect(CyclingRecords.shared.totalCyclingTime == 0)
    #expect(CyclingRecords.shared.totalCyclingDistance == 0)
    #expect(CyclingRecords.shared.totalCyclingRoutes == 0)
    #expect(CyclingRecords.shared.longestCyclingDistance == 0)
    #expect(CyclingRecords.shared.longestCyclingTime == 0)
    #expect(CyclingRecords.shared.fastestAverageSpeed == 0)
    #expect(CyclingRecords.shared.fastestAverageSpeedDate == nil)
    #expect(CyclingRecords.shared.longestCyclingDistanceDate == nil)
    #expect(CyclingRecords.shared.longestCyclingTimeDate == nil)
    #expect(CyclingRecords.shared.unlockedIcons == unlockedIcons)
  }
}

private func seedRecordStores(
  totalTime: Double,
  totalDistance: Double,
  unlockedIcons: [Bool],
  longestDistance: Double,
  longestTime: Double,
  fastestAverageSpeed: Double,
  fastestAverageSpeedDate: Date?,
  longestDistanceDate: Date?,
  longestTimeDate: Date?,
  totalRoutes: Int
) {
  UserDefaults.standard.set(false, forKey: iCloudSyncPreferenceKey)
  setRecordValue(true, forKey: "didSetupRecords")
  setRecordValue(totalTime, forKey: "totalCyclingTime")
  setRecordValue(totalDistance, forKey: "totalCyclingDistance")
  setRecordValue(unlockedIcons, forKey: "unlockedIcons")
  setRecordValue(longestDistance, forKey: "longestCyclingDistance")
  setRecordValue(longestTime, forKey: "longestCyclingTime")
  setRecordValue(fastestAverageSpeed, forKey: "fastestAverageSpeed")
  setRecordValue(fastestAverageSpeedDate, forKey: "fastestAverageSpeedDate")
  setRecordValue(longestDistanceDate, forKey: "longestCyclingDistanceDate")
  setRecordValue(longestTimeDate, forKey: "longestCyclingTimeDate")
  setRecordValue(totalRoutes, forKey: "totalCyclingRoutes")
}

private func setRecordValue(_ value: Any?, forKey key: String) {
  if let value {
    UserDefaults.standard.set(value, forKey: key)
    NSUbiquitousKeyValueStore.default.set(value, forKey: key)
  } else {
    UserDefaults.standard.removeObject(forKey: key)
    NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
  }
}

private func expectFastestAverageSpeedUnchanged(
  records: CyclingRecords,
  fastestAverageSpeed: Double,
  fastestAverageSpeedDate: Date,
  assertICloud: Bool
) {
  #expect(records.fastestAverageSpeed == fastestAverageSpeed)
  #expect(records.fastestAverageSpeedDate == fastestAverageSpeedDate)
  #expect(UserDefaults.standard.double(forKey: "fastestAverageSpeed") == fastestAverageSpeed)
  #expect(
    UserDefaults.standard.object(forKey: "fastestAverageSpeedDate") as? Date
      == fastestAverageSpeedDate)
  // TODO(#24): Replace this runtime iCloud guard with deterministic unavailable-store coverage.
  if assertICloud {
    #expect(
      NSUbiquitousKeyValueStore.default.double(forKey: "fastestAverageSpeed")
        == fastestAverageSpeed)
    #expect(
      NSUbiquitousKeyValueStore.default.object(forKey: "fastestAverageSpeedDate") as? Date
        == fastestAverageSpeedDate)
  }
}

private func expectPersistedRecords(
  totalTime: Double,
  totalDistance: Double,
  unlockedIcons: [Bool],
  longestDistance: Double,
  longestTime: Double,
  fastestAverageSpeed: Double,
  fastestAverageSpeedDate: Date?,
  longestDistanceDate: Date?,
  longestTimeDate: Date?,
  totalRoutes: Int,
  assertICloud: Bool
) {
  #expect(UserDefaults.standard.double(forKey: "totalCyclingTime") == totalTime)
  #expect(UserDefaults.standard.double(forKey: "totalCyclingDistance") == totalDistance)
  #expect(UserDefaults.standard.array(forKey: "unlockedIcons") as? [Bool] == unlockedIcons)
  #expect(UserDefaults.standard.double(forKey: "longestCyclingDistance") == longestDistance)
  #expect(UserDefaults.standard.double(forKey: "longestCyclingTime") == longestTime)
  #expect(UserDefaults.standard.double(forKey: "fastestAverageSpeed") == fastestAverageSpeed)
  #expect(
    UserDefaults.standard.object(forKey: "fastestAverageSpeedDate") as? Date
      == fastestAverageSpeedDate)
  #expect(
    UserDefaults.standard.object(forKey: "longestCyclingDistanceDate") as? Date
      == longestDistanceDate)
  #expect(
    UserDefaults.standard.object(forKey: "longestCyclingTimeDate") as? Date == longestTimeDate)
  #expect(UserDefaults.standard.integer(forKey: "totalCyclingRoutes") == totalRoutes)

  // TODO(#24): Replace this runtime iCloud guard with deterministic unavailable-store coverage.
  if assertICloud {
    #expect(NSUbiquitousKeyValueStore.default.double(forKey: "totalCyclingTime") == totalTime)
    #expect(
      NSUbiquitousKeyValueStore.default.double(forKey: "totalCyclingDistance") == totalDistance)
    #expect(
      NSUbiquitousKeyValueStore.default.array(forKey: "unlockedIcons") as? [Bool] == unlockedIcons)
    #expect(
      NSUbiquitousKeyValueStore.default.double(forKey: "longestCyclingDistance") == longestDistance)
    #expect(NSUbiquitousKeyValueStore.default.double(forKey: "longestCyclingTime") == longestTime)
    #expect(
      NSUbiquitousKeyValueStore.default.double(forKey: "fastestAverageSpeed") == fastestAverageSpeed
    )
    #expect(
      NSUbiquitousKeyValueStore.default.object(forKey: "fastestAverageSpeedDate") as? Date
        == fastestAverageSpeedDate
    )
    #expect(
      NSUbiquitousKeyValueStore.default.object(forKey: "longestCyclingDistanceDate") as? Date
        == longestDistanceDate
    )
    #expect(
      NSUbiquitousKeyValueStore.default.object(forKey: "longestCyclingTimeDate") as? Date
        == longestTimeDate
    )
    #expect(NSUbiquitousKeyValueStore.default.longLong(forKey: "totalCyclingRoutes") == totalRoutes)
  }
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
