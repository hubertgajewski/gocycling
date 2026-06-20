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
    let snapshot = await PersistedStoreSnapshot(
      keys: [iCloudSyncPreferenceKey] + cyclingRecordStoreKeys
    )
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
        cleanupAfterSuccess: {
          cleanupCallCount += 1
        },
        completion: { _ in
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
      cleanupAfterSuccess: {
        locationCleanup.clearCompletedRouteData()
        cleanupCallCount += 1
      },
      alwaysCleanup: {
        locationCleanup.endCyclingSession()
        locationCleanup.stopTrackingBackgroundLocation()
      },
      completion: { _ in
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
    #expect(
      locationCleanup.events == [
        .clearCompletedRouteData, .endCyclingSession, .stopTrackingBackgroundLocation,
      ])
    #expect(cleanupCallCount == 1)
    #expect(completionCallCount == 1)
  }

  @Test("does not update records but still cleans up when persistence fails")
  func doesNotUpdateRecordsButStillCleansUpWhenPersistenceFails() {
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
    var successCleanupCallCount = 0
    var alwaysCleanupCallCount = 0
    var completionResult: Result<BikeRide, Error>?
    let saver = CompletedRouteSaveCoordinator(
      persistenceController: persistence,
      records: records
    )

    saver.save(
      completedRoute,
      cleanupAfterSuccess: {
        locationCleanup.clearCompletedRouteData()
        successCleanupCallCount += 1
      },
      alwaysCleanup: {
        locationCleanup.endCyclingSession()
        locationCleanup.stopTrackingBackgroundLocation()
        alwaysCleanupCallCount += 1
      },
      completion: { result in
        completionResult = result
      }
    )

    #expect(records.updates.isEmpty)
    #expect(locationCleanup.events.isEmpty)
    #expect(successCleanupCallCount == 0)
    #expect(alwaysCleanupCallCount == 0)

    persistence.finishSave(result: .failure(RouteSaveTestError.saveFailed))

    #expect(records.updates.isEmpty)
    #expect(locationCleanup.events == [.endCyclingSession, .stopTrackingBackgroundLocation])
    #expect(successCleanupCallCount == 0)
    #expect(alwaysCleanupCallCount == 1)
    guard case .failure(let error as RouteSaveTestError) = completionResult else {
      Issue.record("Expected save failure result")
      return
    }
    #expect(error == .saveFailed)
  }

  #if DEBUG
    @Test("UI testing skips app launch migration stores")
    func uiTestingSkipsAppLaunchMigrationStores() {
      let userDefaults = RecordingAppLaunchKeyValueStore()
      let ubiquitousStore = RecordingAppLaunchKeyValueStore()
      var preferenceMigrationCount = 0
      var recordsMigrationCount = 0

      AppLaunchMigration.runIfNeeded(
        arguments: [UITesting.launchArgument],
        userDefaults: userDefaults,
        ubiquitousStore: ubiquitousStore,
        migratePreferences: {
          preferenceMigrationCount += 1
        },
        migrateRecords: {
          recordsMigrationCount += 1
        }
      )

      #expect(userDefaults.boolReads.isEmpty)
      #expect(userDefaults.boolWrites.isEmpty)
      #expect(ubiquitousStore.boolReads.isEmpty)
      #expect(ubiquitousStore.boolWrites.isEmpty)
      #expect(preferenceMigrationCount == 0)
      #expect(recordsMigrationCount == 0)
    }

    @Test("UI testing skips app launch telemetry")
    func uiTestingSkipsAppLaunchTelemetry() {
      let userDefaults = RecordingAppLaunchPreferenceStore()
      var setupCalls: [(appID: String, enabled: Bool)] = []

      AppLaunchTelemetry.configureIfNeeded(
        arguments: [UITesting.launchArgument],
        appID: "test-app",
        userDefaults: userDefaults,
        setup: { appID, enabled in
          setupCalls.append((appID, enabled))
        }
      )

      #expect(userDefaults.objectReads.isEmpty)
      #expect(userDefaults.boolReads.isEmpty)
      #expect(setupCalls.isEmpty)
    }

    @Test("normal app launch migration still runs")
    func normalAppLaunchMigrationStillRuns() {
      let userDefaults = RecordingAppLaunchKeyValueStore()
      let ubiquitousStore = RecordingAppLaunchKeyValueStore()
      var preferenceMigrationCount = 0
      var recordsMigrationCount = 0

      AppLaunchMigration.runIfNeeded(
        arguments: [],
        userDefaults: userDefaults,
        ubiquitousStore: ubiquitousStore,
        migratePreferences: {
          preferenceMigrationCount += 1
        },
        migrateRecords: {
          recordsMigrationCount += 1
        }
      )

      #expect(userDefaults.boolWrites.count == 1)
      #expect(ubiquitousStore.boolWrites.count == 1)
      #expect(preferenceMigrationCount == 1)
      #expect(recordsMigrationCount == 1)
    }

    @Test("normal app launch telemetry uses stored preference")
    func normalAppLaunchTelemetryUsesStoredPreference() {
      let userDefaults = RecordingAppLaunchPreferenceStore(
        objectValues: [Preferences.telemetryEnabledKey: false],
        boolValues: [Preferences.telemetryEnabledKey: false]
      )
      var setupCalls: [(appID: String, enabled: Bool)] = []

      AppLaunchTelemetry.configureIfNeeded(
        arguments: [],
        appID: "test-app",
        userDefaults: userDefaults,
        setup: { appID, enabled in
          setupCalls.append((appID, enabled))
        }
      )

      #expect(userDefaults.objectReads == [Preferences.telemetryEnabledKey])
      #expect(userDefaults.boolReads == [Preferences.telemetryEnabledKey])
      #expect(setupCalls.count == 1)
      #expect(setupCalls.first?.appID == "test-app")
      #expect(setupCalls.first?.enabled == false)
    }
  #endif
}

private enum RouteSaveTestError: Error, Equatable {
  case saveFailed
}

private final class RecordingLocationCleanup {
  enum Event {
    case clearCompletedRouteData
    case endCyclingSession
    case stopTrackingBackgroundLocation
  }

  private(set) var events: [Event] = []

  func clearCompletedRouteData() {
    events.append(.clearCompletedRouteData)
  }

  func endCyclingSession() {
    events.append(.endCyclingSession)
  }

  func stopTrackingBackgroundLocation() {
    events.append(.stopTrackingBackgroundLocation)
  }
}

private final class ControllableBikeRidePersistence: BikeRideStoring {
  private let savedRideContext = PersistenceController(inMemory: true).container.viewContext
  private var completion: ((Result<BikeRide, Error>) -> Void)?

  func storeBikeRide(
    locations: [CLLocation?],
    speeds: [CLLocationSpeed?],
    distance: Double,
    elevations: [CLLocationDistance?],
    startTime: Date,
    time: Double,
    completion: @escaping (Result<BikeRide, Error>) -> Void
  ) {
    self.completion = completion
  }

  func finishSave(result: Result<BikeRide, Error>? = nil) {
    completion?(result ?? .success(BikeRide(context: savedRideContext)))
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

private final class RecordingAppLaunchKeyValueStore: AppLaunchKeyValueStore {
  private(set) var boolReads: [String] = []
  private(set) var boolWrites: [(key: String, value: Bool)] = []
  private var boolValues: [String: Bool]

  init(boolValues: [String: Bool] = [:]) {
    self.boolValues = boolValues
  }

  func bool(forKey defaultName: String) -> Bool {
    boolReads.append(defaultName)
    return boolValues[defaultName] ?? false
  }

  func set(_ value: Bool, forKey defaultName: String) {
    boolWrites.append((defaultName, value))
    boolValues[defaultName] = value
  }
}

private final class RecordingAppLaunchPreferenceStore: AppLaunchPreferenceStore {
  private(set) var objectReads: [String] = []
  private(set) var boolReads: [String] = []
  private let objectValues: [String: Any]
  private let boolValues: [String: Bool]

  init(objectValues: [String: Any] = [:], boolValues: [String: Bool] = [:]) {
    self.objectValues = objectValues
    self.boolValues = boolValues
  }

  func object(forKey defaultName: String) -> Any? {
    objectReads.append(defaultName)
    return objectValues[defaultName]
  }

  func bool(forKey defaultName: String) -> Bool {
    boolReads.append(defaultName)
    return boolValues[defaultName] ?? false
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
