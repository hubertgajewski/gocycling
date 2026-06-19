//
//  Go_CyclingApp.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-03-14.
//

import CoreData
import SwiftUI
import TelemetryDeck

// Unit tests need to exercise launch decisions without running App.init, and the
// launch work normally reads/writes process-wide defaults and iCloud state.
protocol AppLaunchKeyValueStore {
    func bool(forKey defaultName: String) -> Bool
    func set(_ value: Bool, forKey defaultName: String)
}

protocol AppLaunchPreferenceStore {
    func object(forKey defaultName: String) -> Any?
    func bool(forKey defaultName: String) -> Bool
}

extension NSUbiquitousKeyValueStore: AppLaunchKeyValueStore {}
extension UserDefaults: AppLaunchKeyValueStore {}
extension UserDefaults: AppLaunchPreferenceStore {}

enum AppLaunchTelemetry {
    // UI-smoke tests need telemetry skipped before TelemetryManager reads
    // preferences or starts network work, so setup is testable outside App.init.
    static func configureIfNeeded(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        appID: Any? = nil,
        userDefaults: AppLaunchPreferenceStore? = nil,
        setup: (String, Bool) -> Void = { appID, telemetryEnabled in
            TelemetryManager.setup(
                TelemetryManager.TelemetryManagerConfig(appID: appID),
                enabled: telemetryEnabled
            )
        }
    ) {
        // UI tests relaunch often on shared devices; skip telemetry setup so test
        // launches do not read or mutate the user's launch-time preferences.
        guard !UITesting.shouldUseIsolatedPersistence(arguments: arguments) else { return }

        let appID = appID ?? Bundle.main.object(forInfoDictionaryKey: "GoCyclingAppID")
        guard let appID = appID as? String else { return }
        let userDefaults = userDefaults ?? UserDefaults.standard
        let telemetryEnabled = userDefaults.object(forKey: Preferences.telemetryEnabledKey) != nil
            ? userDefaults.bool(forKey: Preferences.telemetryEnabledKey)
            : true
        setup(appID, telemetryEnabled)
    }
}

enum AppLaunchMigration {
    static let didLaunchBeforeKey = "didLaunch1.4.0Before"

    // UI-smoke tests need migrations bypassed because they write first-run
    // sentinels and can migrate legacy data in the user's real defaults/iCloud stores.
    static func runIfNeeded(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        userDefaults: AppLaunchKeyValueStore? = nil,
        ubiquitousStore: AppLaunchKeyValueStore? = nil,
        migratePreferences: () -> Void,
        migrateRecords: () -> Void
    ) {
        // UI-smoke tests start from fixture state; running launch migrations there
        // would write real defaults/iCloud keys outside the isolated Core Data store.
        guard !UITesting.shouldUseIsolatedPersistence(arguments: arguments) else { return }

        let userDefaults = userDefaults ?? UserDefaults.standard
        let ubiquitousStore = ubiquitousStore ?? NSUbiquitousKeyValueStore.default
        if !ubiquitousStore.bool(forKey: didLaunchBeforeKey) || !userDefaults.bool(forKey: didLaunchBeforeKey) {
            ubiquitousStore.set(true, forKey: didLaunchBeforeKey)
            userDefaults.set(true, forKey: didLaunchBeforeKey)
            migratePreferences()
            migrateRecords()
        }
    }
}

// Groups launch-time storage decisions so persistence is selected once before
// storage-backed state objects, views, or migrations can touch Core Data.
struct AppLaunchStorage {
    // Keep the launch arguments with the selected storage so later launch gates
    // use the same UI-test mode that built persistence, preferences, and records.
    let arguments: [String]
    let persistenceController: PersistenceController
    let bikeRides: BikeRideStorage
    let preferences: Preferences
    let records: CyclingRecords

    // Migration helpers read through this selected context instead of resolving
    // PersistenceController.shared again after launch-store selection.
    var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }

    func savedPreferences() -> UserPreferences? {
        UserPreferences.savedPreferences(in: viewContext)
    }

    func storedRecords() -> Records? {
        Records.getStoredRecords(in: viewContext)
    }

    var shouldUseIsolatedPersistence: Bool {
        UITesting.shouldUseIsolatedPersistence(arguments: arguments)
    }

    var shouldSeedRouteSaveFixture: Bool {
        UITesting.shouldSeedRouteSaveFixture(arguments: arguments)
    }

    // UI-test launches must select the isolated Core Data store before any
    // storage-backed state object or legacy migration can touch production data.
    // Production still resolves to the existing shared app singletons.
    // The default factories keep production on shared singletons, but UI-test
    // arguments must create argument-scoped state so they do not mutate defaults.
    static func make() -> AppLaunchStorage {
        make(
            arguments: ProcessInfo.processInfo.arguments,
            persistenceControllerFactory: { _ in PersistenceController.shared }
        )
    }

    // Tests pass synthetic launch arguments here, so the persistence factory is
    // explicit to prevent a UI-test argument set from silently using shared data.
    static func make(
        arguments: [String],
        persistenceControllerFactory: ([String]) -> PersistenceController,
        bikeRideStorageFactory: (NSManagedObjectContext) -> BikeRideStorage = {
            BikeRideStorage(managedObjectContext: $0)
        },
        preferencesFactory: ([String]) -> Preferences = { arguments in
            if UITesting.shouldUseIsolatedPersistence(arguments: arguments) {
                return Preferences(arguments: arguments)
            }
            return Preferences.shared
        },
        recordsFactory: ([String]) -> CyclingRecords = { arguments in
            if UITesting.shouldUseIsolatedPersistence(arguments: arguments) {
                return CyclingRecords(arguments: arguments)
            }
            return CyclingRecords.shared
        }
    ) -> AppLaunchStorage {
        let persistenceController = persistenceControllerFactory(arguments)
        let bikeRides = bikeRideStorageFactory(persistenceController.container.viewContext)
        let preferences = preferencesFactory(arguments)
        let records = recordsFactory(arguments)

        return AppLaunchStorage(
            arguments: arguments,
            persistenceController: persistenceController,
            bikeRides: bikeRides,
            preferences: preferences,
            records: records
        )
    }
}

@main
struct GoCyclingApp: App {

    // Retain the selected launch storage so onAppear migrations use the same
    // context that was injected into the first rendered view hierarchy.
    private let launchStorage: AppLaunchStorage
    let persistenceController: PersistenceController
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var bikeRides: BikeRideStorage
    @StateObject var cyclingStatus: CyclingStatus
    @StateObject var preferences: Preferences
    @StateObject var records: CyclingRecords
    
    init() {
        self.init(launchStorage: .make())
    }

    init(launchStorage: AppLaunchStorage) {
        // Construct every storage-backed StateObject from the launch seam so the
        // app cannot mix isolated UI-test storage with production singletons.
        self.launchStorage = launchStorage
        self.persistenceController = launchStorage.persistenceController
        self._bikeRides = StateObject(wrappedValue: launchStorage.bikeRides)
        self._preferences = StateObject(wrappedValue: launchStorage.preferences)
        self._records = StateObject(wrappedValue: launchStorage.records)
        self._cyclingStatus = StateObject(wrappedValue: CyclingStatus())

        // Telemetry reads user defaults during setup; pass the selected launch
        // arguments so UI-test launches keep that side effect disabled.
        AppLaunchTelemetry.configureIfNeeded(arguments: launchStorage.arguments)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(bikeRides)
                .environmentObject(records)
                .environmentObject(cyclingStatus)
                .environmentObject(preferences)
                .onAppear(perform: {
                    #if DEBUG
                    // UI-smoke tests need a saved route from the real save path so
                    // History is verified without relying on live GPS/timer data.
                    if launchStorage.shouldSeedRouteSaveFixture {
                        UITestingRouteSaveFixture.runIfNeeded(
                            persistenceController: persistenceController
                        )
                        return
                    }
                    #endif

                    // UI-smoke tests need to stop here because the remaining launch
                    // work can mutate real preferences or telemetry state.
                    guard !launchStorage.shouldUseIsolatedPersistence else { return }

                    // Legacy Core Data migration must read from the selected
                    // launch store before migrated values are copied to defaults.
                    AppLaunchMigration.runIfNeeded(
                        arguments: launchStorage.arguments,
                        migratePreferences: {
                            if let oldPreferences = launchStorage.savedPreferences() {
                                preferences.initialUserPreferencesMigration(
                                    existingPreferences: oldPreferences
                                )
                            }
                        },
                        migrateRecords: {
                            if let oldRecords = launchStorage.storedRecords() {
                                records.initialRecordsMigration(
                                    existingRecords: oldRecords,
                                    existingBikeRides: bikeRides.storedBikeRides
                                )
                            }
                        }
                    )
                    
                    // Disable auto lock if that setting is enabled
                    if (preferences.autoLockDisabled) {
                        UIApplication.shared.isIdleTimerDisabled = true
                    }

                    // Gate mid-session telemetry signals based on stored preference
                    TelemetryManager.sharedTelemetryManager.userTelemetryEnabled = preferences.telemetryEnabled
                })
        }
        .onChange(of: scenePhase) { _ in
            persistenceController.save()
        }
    }
}
