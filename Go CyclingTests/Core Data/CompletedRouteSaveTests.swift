//
//  CompletedRouteSaveTests.swift
//  Go CyclingTests
//

import CoreData
import CoreLocation
import Foundation
import Testing

@testable import Go_Cycling

@Suite("Completed route save", .serialized)
@MainActor
struct CompletedRouteSaveTests {

  @Test("saves route data, updates records, and runs cleanup")
  func savesRouteDataUpdatesRecordsAndRunsCleanup() async throws {
    let snapshot = PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey] + cyclingRecordStoreKeys)
    defer { snapshot.restore() }

    prepareRecordStore()
    let persistence = makeInMemoryPersistenceController()
    let records = CyclingRecords()
    let startTime = Date(timeIntervalSince1970: 1_800)
    let completedRoute = CompletedRouteSnapshot(
      locations: [
        CLLocation(latitude: 51.5, longitude: -0.12),
        nil,
        CLLocation(latitude: 52.0, longitude: -0.2),
      ],
      speeds: [4.2, nil, 5.5],
      distance: 1_500,
      elevations: [15, nil, 21],
      startTime: startTime,
      time: 300
    )
    var cleanupCallCount = 0
    let saver = CompletedRouteSaveCoordinator(
      persistenceController: persistence,
      records: records
    )

    await withCheckedContinuation { continuation in
      saver.save(
        completedRoute,
        cleanup: {
          cleanupCallCount += 1
        },
        completion: {
          continuation.resume()
        }
      )
    }

    let rides = try fetchRides(in: persistence.container.viewContext)
    #expect(rides.count == 1)
    let ride = try #require(rides.first)
    #expect(ride.cyclingLatitudes == [51.5, 52.0])
    #expect(ride.cyclingLongitudes == [-0.12, -0.2])
    #expect(ride.cyclingSpeeds == [4.2, 5.5])
    #expect(ride.cyclingDistance == 1_500)
    #expect(ride.cyclingElevations == [15, 21])
    #expect(ride.cyclingStartTime == startTime)
    #expect(ride.cyclingTime == 300)
    #expect(ride.cyclingRouteName == "Uncategorized")

    #expect(records.totalCyclingDistance == 1_500)
    #expect(records.totalCyclingTime == 300)
    #expect(records.totalCyclingRoutes == 1)
    #expect(records.longestCyclingDistance == 1_500)
    #expect(records.longestCyclingTime == 300)
    #expect(records.fastestAverageSpeed == 5)
    #expect(records.longestCyclingDistanceDate == startTime)
    #expect(records.longestCyclingTimeDate == startTime)
    #expect(records.fastestAverageSpeedDate == startTime)
    #expect(records.unlockedIcons == [false, false, false, false, false, false])
    #expect(cleanupCallCount == 1)
  }

  @Test("waits for persistence before records and cleanup")
  func waitsForPersistenceBeforeRecordsAndCleanup() {
    let persistence = ControllableBikeRidePersistence()
    let records = RecordingCyclingRecordsUpdater()
    let locationCleanup = RecordingLocationCleanup()
    let completedRoute = CompletedRouteSnapshot(
      locations: [CLLocation(latitude: 51.5, longitude: -0.12)],
      speeds: [7],
      distance: 1_200,
      elevations: [11],
      startTime: Date(timeIntervalSince1970: 2_400),
      time: 240
    )
    var cleanupCallCount = 0
    var completionCallCount = 0
    let saver = CompletedRouteSaveCoordinator(
      persistenceController: persistence,
      records: records
    )

    saver.save(
      completedRoute,
      cleanup: {
        locationCleanup.clearLocationArray()
        locationCleanup.stopTrackingBackgroundLocation()
        cleanupCallCount += 1
      },
      completion: {
        completionCallCount += 1
      }
    )

    #expect(records.updates.isEmpty)
    #expect(locationCleanup.events.isEmpty)
    #expect(cleanupCallCount == 0)
    #expect(completionCallCount == 0)

    persistence.finishSave()

    #expect(records.updates.count == 1)
    #expect(records.updates.first?.distance == 1_200)
    #expect(records.updates.first?.time == 240)
    #expect(locationCleanup.events == [.clearLocationArray, .stopTrackingBackgroundLocation])
    #expect(cleanupCallCount == 1)
    #expect(completionCallCount == 1)
  }
}

private final class RecordingLocationCleanup {
  enum Event {
    case clearLocationArray
    case stopTrackingBackgroundLocation
  }

  private(set) var events: [Event] = []

  func clearLocationArray() {
    events.append(.clearLocationArray)
  }

  func stopTrackingBackgroundLocation() {
    events.append(.stopTrackingBackgroundLocation)
  }
}

private final class ControllableBikeRidePersistence: BikeRideStoring {
  private(set) var storeCallCount = 0
  private var completion: (() -> Void)?

  func storeBikeRide(
    locations: [CLLocation?],
    speeds: [CLLocationSpeed?],
    distance: Double,
    elevations: [CLLocationDistance?],
    startTime: Date,
    time: Double,
    completion: @escaping () -> Void
  ) {
    storeCallCount += 1
    self.completion = completion
  }

  func finishSave() {
    completion?()
  }
}

private final class RecordingCyclingRecordsUpdater: CyclingRecordsUpdating {
  struct Update {
    let speeds: [CLLocationSpeed?]
    let distance: Double
    let startTime: Date
    let time: Double
  }

  private(set) var updates: [Update] = []

  func updateCyclingRecords(
    speeds: [CLLocationSpeed?],
    distance: Double,
    startTime: Date,
    time: Double
  ) {
    updates.append(
      Update(
        speeds: speeds,
        distance: distance,
        startTime: startTime,
        time: time
      )
    )
  }
}

private func makeInMemoryPersistenceController() -> PersistenceController {
  UserDefaults.standard.set(false, forKey: iCloudSyncPreferenceKey)
  return PersistenceController(inMemory: true)
}

private func prepareRecordStore() {
  UserDefaults.standard.set(false, forKey: iCloudSyncPreferenceKey)
  UserDefaults.standard.set(true, forKey: "didSetupRecords")
  UserDefaults.standard.set(0.0, forKey: "totalCyclingTime")
  UserDefaults.standard.set(0.0, forKey: "totalCyclingDistance")
  UserDefaults.standard.set([false, false, false, false, false, false], forKey: "unlockedIcons")
  UserDefaults.standard.set(0.0, forKey: "longestCyclingDistance")
  UserDefaults.standard.set(0.0, forKey: "longestCyclingTime")
  UserDefaults.standard.set(0.0, forKey: "fastestAverageSpeed")
  UserDefaults.standard.removeObject(forKey: "fastestAverageSpeedDate")
  UserDefaults.standard.removeObject(forKey: "longestCyclingDistanceDate")
  UserDefaults.standard.removeObject(forKey: "longestCyclingTimeDate")
  UserDefaults.standard.set(0, forKey: "totalCyclingRoutes")
}

private func fetchRides(in context: NSManagedObjectContext) throws -> [BikeRide] {
  let request: NSFetchRequest<BikeRide> = BikeRide.fetchRequest()
  request.sortDescriptors = [
    NSSortDescriptor(keyPath: \BikeRide.cyclingStartTime, ascending: true)
  ]
  return try context.fetch(request)
}
