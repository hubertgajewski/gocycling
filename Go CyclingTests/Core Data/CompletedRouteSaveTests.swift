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
    @Test("route save fixture leaves standard defaults unchanged")
    func routeSaveFixtureLeavesStandardDefaultsUnchanged() async throws {
      let keys = [iCloudSyncPreferenceKey, "selectedRoute"] + cyclingRecordStoreKeys
      let snapshot = await PersistedStoreSnapshot(keys: keys)
      defer {
        UITestingRouteSaveFixture.resetForTesting()
        snapshot.restore()
      }
      let persistence = PersistenceController(arguments: UITesting.routeSaveFixtureLaunchArguments)
      let records = RecordingCyclingRecordsUpdater()
      seedFixtureSentinels()
      UITestingRouteSaveFixture.resetForTesting()

      var saveResult: Result<Void, Error>?
      await withCheckedContinuation { continuation in
        UITestingRouteSaveFixture.runIfNeeded(
          persistenceController: persistence,
          records: records,
          arguments: UITesting.routeSaveFixtureLaunchArguments,
          completion: { result in
            saveResult = result
            continuation.resume()
          }
        )
      }

      guard case .success = saveResult else {
        Issue.record("Expected route-save fixture to seed the ride")
        return
      }
      let rides = try fetchRides(in: persistence.container.viewContext)
      #expect(rides.count == 1)
      #expect(records.updates.count == 1)
      assertFixtureSentinelsUnchanged()
    }

    @Test("UI testing alone isolates without seeding route fixture")
    func uiTestingAloneIsolatesWithoutSeedingRouteFixture() {
      #expect(UITesting.shouldUseIsolatedPersistence(arguments: [UITesting.launchArgument]))
      #expect(!UITesting.shouldSeedRouteSaveFixture(arguments: [UITesting.launchArgument]))
      #expect(
        UITesting.shouldSeedRouteSaveFixture(arguments: UITesting.routeSaveFixtureLaunchArguments))
    }

    @Test("route save fixture refuses non-isolated stores")
    func routeSaveFixtureRefusesNonIsolatedStores() async throws {
      let persistence = PersistenceController(inMemory: true)
      try insertRide(in: persistence.container.viewContext)
      let records = RecordingCyclingRecordsUpdater()
      UITestingRouteSaveFixture.resetForTesting()

      var saveResult: Result<Void, Error>?
      await withCheckedContinuation { continuation in
        UITestingRouteSaveFixture.runIfNeeded(
          persistenceController: persistence,
          records: records,
          arguments: UITesting.routeSaveFixtureLaunchArguments,
          completion: { result in
            saveResult = result
            continuation.resume()
          }
        )
      }

      guard case .failure(let error as UITestingRouteSaveFixtureError) = saveResult else {
        Issue.record("Expected the fixture to reject a non-isolated store")
        return
      }
      #expect(error == .nonIsolatedStore)
      #expect(try fetchRides(in: persistence.container.viewContext).count == 1)
      #expect(records.updates.isEmpty)
    }

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

    @Test("route save fixture model initialization leaves stores unchanged")
    func routeSaveFixtureModelInitializationLeavesStoresUnchanged() async {
      let keys = routeSaveFixturePreferenceStoreKeys + cyclingRecordStoreKeys
      let snapshot = await PersistedStoreSnapshot(keys: keys)
      defer { snapshot.restore() }
      seedRouteSaveFixtureModelSentinels()

      let preferences = Preferences(arguments: UITesting.routeSaveFixtureLaunchArguments)
      let records = CyclingRecords(arguments: UITesting.routeSaveFixtureLaunchArguments)

      #expect(preferences.selectedRoute == "")
      #expect(preferences.iCloudOn == false)
      #expect(preferences.autoLockDisabled == false)
      #expect(preferences.telemetryEnabled == true)
      #expect(records.totalCyclingTime == 0)
      #expect(records.totalCyclingDistance == 0)
      #expect(records.totalCyclingRoutes == 0)
      #expect(records.unlockedIcons == [false, false, false, false, false, false])
      assertRouteSaveFixtureModelSentinelsUnchanged()
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

private func seedFixtureSentinels() {
  setFixtureSentinel(true, forKey: iCloudSyncPreferenceKey)
  setFixtureSentinel("Existing Route", forKey: "selectedRoute")
  setFixtureSentinel(true, forKey: "didSetupRecords")
  setFixtureSentinel(42.0, forKey: "totalCyclingTime")
  setFixtureSentinel(43.0, forKey: "totalCyclingDistance")
  setFixtureSentinel([true, false, true, false, true, false], forKey: "unlockedIcons")
  setFixtureSentinel(44.0, forKey: "longestCyclingDistance")
  setFixtureSentinel(45.0, forKey: "longestCyclingTime")
  setFixtureSentinel(46.0, forKey: "fastestAverageSpeed")
  setFixtureSentinel(Date(timeIntervalSince1970: 47), forKey: "fastestAverageSpeedDate")
  setFixtureSentinel(Date(timeIntervalSince1970: 48), forKey: "longestCyclingDistanceDate")
  setFixtureSentinel(Date(timeIntervalSince1970: 49), forKey: "longestCyclingTimeDate")
  setFixtureSentinel(7, forKey: "totalCyclingRoutes")
}

private func assertFixtureSentinelsUnchanged() {
  assertFixtureSentinel(true, forKey: iCloudSyncPreferenceKey)
  assertFixtureSentinel("Existing Route", forKey: "selectedRoute")
  assertFixtureSentinel(true, forKey: "didSetupRecords")
  assertFixtureSentinel(42.0, forKey: "totalCyclingTime")
  assertFixtureSentinel(43.0, forKey: "totalCyclingDistance")
  assertFixtureSentinel([true, false, true, false, true, false], forKey: "unlockedIcons")
  assertFixtureSentinel(44.0, forKey: "longestCyclingDistance")
  assertFixtureSentinel(45.0, forKey: "longestCyclingTime")
  assertFixtureSentinel(46.0, forKey: "fastestAverageSpeed")
  assertFixtureSentinel(Date(timeIntervalSince1970: 47), forKey: "fastestAverageSpeedDate")
  assertFixtureSentinel(Date(timeIntervalSince1970: 48), forKey: "longestCyclingDistanceDate")
  assertFixtureSentinel(Date(timeIntervalSince1970: 49), forKey: "longestCyclingTimeDate")
  assertFixtureSentinel(7, forKey: "totalCyclingRoutes")
}

private func setFixtureSentinel(_ value: Any, forKey key: String) {
  UserDefaults.standard.set(value, forKey: key)
}

private func fixturePersistentValue(forKey key: String) -> Any? {
  guard let bundleIdentifier = Bundle.main.bundleIdentifier,
    let domain = UserDefaults.standard.persistentDomain(forName: bundleIdentifier)
  else {
    return UserDefaults.standard.object(forKey: key)
  }
  return domain[key]
}

private func assertFixtureSentinel(_ expected: Bool, forKey key: String) {
  #expect(fixturePersistentValue(forKey: key) as? Bool == expected)
}

private func assertFixtureSentinel(_ expected: Int, forKey key: String) {
  #expect(fixturePersistentValue(forKey: key) as? Int == expected)
}

private func assertFixtureSentinel(_ expected: Double, forKey key: String) {
  #expect(fixturePersistentValue(forKey: key) as? Double == expected)
}

private func assertFixtureSentinel(_ expected: String, forKey key: String) {
  #expect(fixturePersistentValue(forKey: key) as? String == expected)
}

private func assertFixtureSentinel(_ expected: [Bool], forKey key: String) {
  #expect(fixturePersistentValue(forKey: key) as? [Bool] == expected)
}

private func assertFixtureSentinel(_ expected: Date, forKey key: String) {
  #expect(fixturePersistentValue(forKey: key) as? Date == expected)
}

private let routeSaveFixturePreferenceStoreKeys = [
  "didSetupPreferences",
  "metric",
  "colour",
  "selectedRoute",
  "autoLockDisabled",
  "iconIndex",
  iCloudSyncPreferenceKey,
  Preferences.telemetryEnabledKey,
]

private func seedRouteSaveFixtureModelSentinels() {
  setFixtureSentinel(false, forKey: "didSetupPreferences")
  setFixtureSentinel(false, forKey: "metric")
  setFixtureSentinel("Existing Colour", forKey: "colour")
  setFixtureSentinel("Existing Route", forKey: "selectedRoute")
  setFixtureSentinel(true, forKey: "autoLockDisabled")
  setFixtureSentinel(9, forKey: "iconIndex")
  setFixtureSentinel(true, forKey: iCloudSyncPreferenceKey)
  setFixtureSentinel(false, forKey: Preferences.telemetryEnabledKey)
  seedFixtureSentinels()
}

private func assertRouteSaveFixtureModelSentinelsUnchanged() {
  assertFixtureSentinel(false, forKey: "didSetupPreferences")
  assertFixtureSentinel(false, forKey: "metric")
  assertFixtureSentinel("Existing Colour", forKey: "colour")
  assertFixtureSentinel("Existing Route", forKey: "selectedRoute")
  assertFixtureSentinel(true, forKey: "autoLockDisabled")
  assertFixtureSentinel(9, forKey: "iconIndex")
  assertFixtureSentinel(true, forKey: iCloudSyncPreferenceKey)
  assertFixtureSentinel(false, forKey: Preferences.telemetryEnabledKey)
  assertFixtureSentinelsUnchanged()
}

@discardableResult
private func insertRide(in context: NSManagedObjectContext) throws -> BikeRide {
  let ride = BikeRide(context: context)
  ride.cyclingLatitudes = [51.5]
  ride.cyclingLongitudes = [-0.12]
  ride.cyclingSpeeds = [4.2]
  ride.cyclingDistance = 1_500
  ride.cyclingElevations = [15]
  ride.cyclingStartTime = Date(timeIntervalSince1970: 1_800)
  ride.cyclingTime = 300
  ride.cyclingRouteName = "Uncategorized"
  try context.save()
  return ride
}

private func fetchRides(in context: NSManagedObjectContext) throws -> [BikeRide] {
  let request: NSFetchRequest<BikeRide> = BikeRide.fetchRequest()
  request.sortDescriptors = [
    NSSortDescriptor(keyPath: \BikeRide.cyclingStartTime, ascending: true)
  ]
  return try context.fetch(request)
}
