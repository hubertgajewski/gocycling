//
//  Go_CyclingApp.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-03-14.
//

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

@main
struct GoCyclingApp: App {
    
    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var bikeRides: BikeRideStorage
    @StateObject var cyclingStatus = CyclingStatus()
    @StateObject var preferences = Preferences.shared
    @StateObject var records = CyclingRecords.shared
    
    init() {
        AppLaunchTelemetry.configureIfNeeded()
        
        // Retrieve stored data to be used by all views - create state objects for environment objects
        let managedObjectContext = persistenceController.container.viewContext
        let bikeRidesStorage = BikeRideStorage(managedObjectContext: managedObjectContext)
        self._bikeRides = StateObject(wrappedValue: bikeRidesStorage)
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
                    if UITesting.shouldSeedRouteSaveFixture() {
                        UITestingRouteSaveFixture.runIfNeeded(
                            persistenceController: persistenceController
                        )
                        return
                    }
                    #endif

                    // UI-smoke tests need to stop here because the remaining launch
                    // work can mutate real preferences or telemetry state.
                    guard !UITesting.shouldUseIsolatedPersistence() else { return }

                    AppLaunchMigration.runIfNeeded(
                        migratePreferences: {
                            if let oldPreferences = UserPreferences.savedPreferences() {
                                preferences.initialUserPreferencesMigration(existingPreferences: oldPreferences)
                            }
                        },
                        migrateRecords: {
                            if let oldRecords = Records.getStoredRecords() {
                                records.initialRecordsMigration(existingRecords: oldRecords, existingBikeRides: bikeRides.storedBikeRides)
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
