//
//  Preferences.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2022-04-13.
//

import Foundation

// Enum to represent the configurable settings
enum CustomizablePreferences {
    case metric
    case displayingMetrics
    case colour
    case largeMetrics
    case sortingChoice
    case deletionConfirmation
    case deletionEnabled
    case iconIndex
    case namedRoutes
    case selectedRoute
    case iCloudSync
    case autoLockDisabled
    case healthSyncEnabled
    case autoPauseEnabled
    case telemetryEnabled
    case mapTypeChoice
}

// Class to represent the preferences of a user
class Preferences: ObservableObject {
    
    // Singleton instance
    static let shared: Preferences = Preferences()
    
    @Published var usingMetric: Bool
    @Published var displayingMetrics: Bool
    @Published var colourChoice: String
    @Published var largeMetrics: Bool
    @Published var sortingChoice: String
    @Published var deletionConfirmation: Bool
    @Published var deletionEnabled: Bool
    @Published var iconIndex: Int
    @Published var namedRoutes: Bool
    @Published var selectedRoute: String
    @Published var iCloudOn: Bool
    @Published var autoLockDisabled: Bool
    @Published var healthSyncEnabled: Bool
    @Published var autoPauseEnabled: Bool
    @Published var telemetryEnabled: Bool
    @Published var mapTypeChoice: String

    // UI-test launches can exercise Settings controls; keep those selected
    // preference changes in memory so they do not overwrite the user's defaults.
    private let persistsPreferenceUpdates: Bool


    static private let initKey = "didSetupPreferences"
    static private let keys = ["metric", "displayingMetrics", "colour", "largeMetrics", "sortingChoice", "deletionConfirmation", "deletionEnabled", "namedRoutes", "selectedRoute", "autoLockDisabled", "healthSyncEnabled", "autoPauseEnabled", "mapType"]
    // Icon index is a special case since it should only be stored locally
    static private let iconIndexKey = "iconIndex"
    // iCloud sync setting is also only stored locally
    static private let iCloudOnKey = "iCloudOn"
    // Telemetry opt-out is stored locally only (privacy preference should stay device-local)
    static let telemetryEnabledKey = "telemetryEnabled"
    static private let keyTypes = [0, 0, 2, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2] // 0: Bool, 1: Int, 2: String
    // UI-smoke tests need first-launch defaults without writing the normal
    // initialization keys into the user's preferences.
    static private let defaultUsingMetric = true
    static private let defaultDisplayingMetrics = true
    static private let defaultColourChoice = ColourChoice.blue.rawValue
    static private let defaultLargeMetrics = true
    static private let defaultSortingChoice = SortChoice.dateDescending.rawValue
    static private let defaultDeletionConfirmation = true
    static private let defaultDeletionEnabled = true
    static private let defaultNamedRoutes = true
    static private let defaultSelectedRoute = ""
    static private let defaultAutoLockDisabled = false
    static private let defaultHealthSyncEnabled = false
    static private let defaultAutoPauseEnabled = true
    static private let defaultMapTypeChoice = MapTypeChoice.standard.rawValue
    static private let defaultIconIndex = 0
    static private let defaultICloudOn = false
    static private let defaultTelemetryEnabled = true
    
    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let isUsingIsolatedPersistence = UITesting.shouldUseIsolatedPersistence(arguments: arguments)
        self.persistsPreferenceUpdates = !isUsingIsolatedPersistence

        if isUsingIsolatedPersistence {
            // UI-smoke tests need predictable defaults, but writing the normal
            // initialization keys would mutate the user's app preferences.
            self.usingMetric = Preferences.defaultUsingMetric
            self.displayingMetrics = Preferences.defaultDisplayingMetrics
            self.colourChoice = Preferences.defaultColourChoice
            self.largeMetrics = Preferences.defaultLargeMetrics
            self.sortingChoice = Preferences.defaultSortingChoice
            self.deletionConfirmation = Preferences.defaultDeletionConfirmation
            self.deletionEnabled = Preferences.defaultDeletionEnabled
            self.iconIndex = Preferences.defaultIconIndex
            self.namedRoutes = Preferences.defaultNamedRoutes
            self.selectedRoute = Preferences.defaultSelectedRoute
            self.iCloudOn = Preferences.defaultICloudOn
            self.autoLockDisabled = Preferences.defaultAutoLockDisabled
            self.healthSyncEnabled = Preferences.defaultHealthSyncEnabled
            self.autoPauseEnabled = Preferences.defaultAutoPauseEnabled
            self.telemetryEnabled = Preferences.defaultTelemetryEnabled
            self.mapTypeChoice = Preferences.defaultMapTypeChoice
            return
        }

        // First check if iCloud is available
        let iCloudStatus = Preferences.iCloudAvailable()
        
        // Next check if preferences have ever been setup
        var status = Preferences.havePreferencesBeenInitialized()
        
        // On device only if iCloud is off
        if !iCloudStatus {
            if (UserDefaults.standard.object(forKey: Preferences.initKey) == nil) {
                status = 0
            }
            else {
                status = 1
            }
        }
        
        switch status {
        // Nothing is setup
        case 0:
            Preferences.writeDefaults(iCloud: false)
            UserDefaults.standard.set(true, forKey: Preferences.initKey)
            if iCloudStatus {
                Preferences.writeDefaults(iCloud: true)
                NSUbiquitousKeyValueStore.default.set(true, forKey: Preferences.initKey)
            }
        // On device is setup
        case 1:
            if iCloudStatus {
                Preferences.syncLocalAndCloud(localToCloud: true)
                NSUbiquitousKeyValueStore.default.set(true, forKey: Preferences.initKey)
            }
        // iCloud is setup
        case 2:
            if iCloudStatus {
                Preferences.syncLocalAndCloud(localToCloud: false)
                UserDefaults.standard.set(true, forKey: Preferences.initKey)
            }
        // Everything is setup
        case 3:
            if iCloudStatus {
                Preferences.syncLocalAndCloud(localToCloud: false)
            }
        default:
            fatalError("Index out of range")
        }
        
        // Set class attributes based on local copy of data
        self.usingMetric = UserDefaults.standard.bool(forKey: Preferences.keys[0])
        self.displayingMetrics = UserDefaults.standard.bool(forKey: Preferences.keys[1])
        self.colourChoice = UserDefaults.standard.string(forKey: Preferences.keys[2])!
        self.largeMetrics = UserDefaults.standard.bool(forKey: Preferences.keys[3])
        self.sortingChoice = UserDefaults.standard.string(forKey: Preferences.keys[4])!
        self.deletionConfirmation = UserDefaults.standard.bool(forKey: Preferences.keys[5])
        self.deletionEnabled = UserDefaults.standard.bool(forKey: Preferences.keys[6])
        self.namedRoutes = UserDefaults.standard.bool(forKey: Preferences.keys[7])
        self.selectedRoute = UserDefaults.standard.string(forKey: Preferences.keys[8])!
        self.autoLockDisabled = UserDefaults.standard.bool(forKey: Preferences.keys[9])
        self.healthSyncEnabled = UserDefaults.standard.bool(forKey: Preferences.keys[10])
        self.autoPauseEnabled = UserDefaults.standard.object(forKey: Preferences.keys[11]) == nil ? true : UserDefaults.standard.bool(forKey: Preferences.keys[11])
        self.mapTypeChoice = UserDefaults.standard.string(forKey: Preferences.keys[12]) ?? MapTypeChoice.standard.rawValue

        self.iconIndex = UserDefaults.standard.integer(forKey: Preferences.iconIndexKey)
        self.iCloudOn = UserDefaults.standard.bool(forKey: Preferences.iCloudOnKey)
        let storedTelemetry = UserDefaults.standard.object(forKey: Preferences.telemetryEnabledKey)
        self.telemetryEnabled = storedTelemetry != nil
            ? UserDefaults.standard.bool(forKey: Preferences.telemetryEnabledKey)
            : true

        // Used to watch for iCloud NSUbiquitousKeyValueStore change events to sync preferences from other devices
        NotificationCenter.default.addObserver(self, selector: #selector(keysDidChangeOnCloud(notification:)),
                                                       name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                                       object: nil)
    }
    
    @objc func keysDidChangeOnCloud(notification: Notification) {
        // Force this update to run on the main thread, but asynchronously
        DispatchQueue.main.async {
            Preferences.syncLocalAndCloud(localToCloud: false)
            self.writeToClassMembers()
        }
    }
    
    // Read-only converters for Views — use updateBoolPreference/updateStringPreference to write
    var colourChoiceConverted: ColourChoice {
        ColourChoice(rawValue: colourChoice) ?? .blue
    }

    var sortingChoiceConverted: SortChoice {
        SortChoice(rawValue: sortingChoice) ?? .dateDescending
    }

    var metricsChoiceConverted: UnitsChoice {
        usingMetric ? .metric : .imperial
    }

    var mapTypeChoiceConverted: MapTypeChoice {
        MapTypeChoice(rawValue: mapTypeChoice) ?? .standard
    }
    
    // Function to update class members
    private func writeToClassMembers() {
        self.usingMetric = UserDefaults.standard.bool(forKey: Preferences.keys[0])
        self.displayingMetrics = UserDefaults.standard.bool(forKey: Preferences.keys[1])
        self.colourChoice = UserDefaults.standard.string(forKey: Preferences.keys[2])!
        self.largeMetrics = UserDefaults.standard.bool(forKey: Preferences.keys[3])
        self.sortingChoice = UserDefaults.standard.string(forKey: Preferences.keys[4])!
        self.deletionConfirmation = UserDefaults.standard.bool(forKey: Preferences.keys[5])
        self.deletionEnabled = UserDefaults.standard.bool(forKey: Preferences.keys[6])
        self.namedRoutes = UserDefaults.standard.bool(forKey: Preferences.keys[7])
        self.selectedRoute = UserDefaults.standard.string(forKey: Preferences.keys[8])!
        self.autoLockDisabled = UserDefaults.standard.bool(forKey: Preferences.keys[9])
        self.healthSyncEnabled = UserDefaults.standard.bool(forKey: Preferences.keys[10])
        self.autoPauseEnabled = UserDefaults.standard.object(forKey: Preferences.keys[11]) == nil ? true : UserDefaults.standard.bool(forKey: Preferences.keys[11])
        self.mapTypeChoice = UserDefaults.standard.string(forKey: Preferences.keys[12]) ?? MapTypeChoice.standard.rawValue

        self.iconIndex = UserDefaults.standard.integer(forKey: Preferences.iconIndexKey)
        self.iCloudOn = UserDefaults.standard.bool(forKey: Preferences.iCloudOnKey)
        let storedTelemetry = UserDefaults.standard.object(forKey: Preferences.telemetryEnabledKey)
        self.telemetryEnabled = storedTelemetry != nil
            ? UserDefaults.standard.bool(forKey: Preferences.telemetryEnabledKey)
            : true
    }

    static public func iCloudAvailable() -> Bool {
        // Set iCloud preference if it doesn't exist
        if UserDefaults.standard.object(forKey: Preferences.iCloudOnKey) == nil {
            UserDefaults.standard.set(false, forKey: Preferences.iCloudOnKey)
        }
        // Check if iCloud is available
        var iCloudAvailable = false
        if FileManager.default.ubiquityIdentityToken != nil {
            iCloudAvailable = true
        }
        if !UserDefaults.standard.bool(forKey: Preferences.iCloudOnKey) {
            iCloudAvailable = false
        }
        return iCloudAvailable
    }
    
    // 0: Nothing setup, 1: On device setup, 2: iCloud setup, 3: Both iCloud and on device setup
    static private func havePreferencesBeenInitialized() -> Int {
        if (!UserDefaults.standard.bool(forKey: initKey) && !NSUbiquitousKeyValueStore.default.bool(forKey: initKey)) {
            return 0
        }
        else if (UserDefaults.standard.bool(forKey: initKey) && !NSUbiquitousKeyValueStore.default.bool(forKey: initKey)) {
            return 1
        }
        else if (!UserDefaults.standard.bool(forKey: initKey) && NSUbiquitousKeyValueStore.default.bool(forKey: initKey)) {
            return 2
        }
        else {
            return 3
        }
    }
    
    static private func writeDefaults(iCloud: Bool) {
        // Use NSUbiquitousKeyValueStore for iCloud storage
        if iCloud {
            NSUbiquitousKeyValueStore.default.set(defaultUsingMetric, forKey: keys[0])
            NSUbiquitousKeyValueStore.default.set(defaultDisplayingMetrics, forKey: keys[1])
            NSUbiquitousKeyValueStore.default.set(defaultColourChoice, forKey: keys[2])
            NSUbiquitousKeyValueStore.default.set(defaultLargeMetrics, forKey: keys[3])
            NSUbiquitousKeyValueStore.default.set(defaultSortingChoice, forKey: keys[4])
            NSUbiquitousKeyValueStore.default.set(defaultDeletionConfirmation, forKey: keys[5])
            NSUbiquitousKeyValueStore.default.set(defaultDeletionEnabled, forKey: keys[6])
            NSUbiquitousKeyValueStore.default.set(defaultNamedRoutes, forKey: keys[7])
            NSUbiquitousKeyValueStore.default.set(defaultSelectedRoute, forKey: keys[8])
            NSUbiquitousKeyValueStore.default.set(defaultAutoLockDisabled, forKey: keys[9])
            NSUbiquitousKeyValueStore.default.set(defaultHealthSyncEnabled, forKey: keys[10])
            NSUbiquitousKeyValueStore.default.set(defaultAutoPauseEnabled, forKey: keys[11])
            NSUbiquitousKeyValueStore.default.set(defaultMapTypeChoice, forKey: keys[12])
        }
        // Use UserDefaults for local storage
        else {
            UserDefaults.standard.set(defaultUsingMetric, forKey: keys[0])
            UserDefaults.standard.set(defaultDisplayingMetrics, forKey: keys[1])
            UserDefaults.standard.set(defaultColourChoice, forKey: keys[2])
            UserDefaults.standard.set(defaultLargeMetrics, forKey: keys[3])
            UserDefaults.standard.set(defaultSortingChoice, forKey: keys[4])
            UserDefaults.standard.set(defaultDeletionConfirmation, forKey: keys[5])
            UserDefaults.standard.set(defaultDeletionEnabled, forKey: keys[6])
            UserDefaults.standard.set(defaultNamedRoutes, forKey: keys[7])
            UserDefaults.standard.set(defaultSelectedRoute, forKey: keys[8])
            UserDefaults.standard.set(defaultAutoLockDisabled, forKey: keys[9])
            UserDefaults.standard.set(defaultHealthSyncEnabled, forKey: keys[10])
            UserDefaults.standard.set(defaultAutoPauseEnabled, forKey: keys[11])
            UserDefaults.standard.set(defaultMapTypeChoice, forKey: keys[12])
        }

        // Store iconIndex locally in either case
        UserDefaults.standard.set(defaultIconIndex, forKey: iconIndexKey)
    }
    
    static private func syncLocalAndCloud(localToCloud: Bool) {
        // Only sync if available
        if Preferences.iCloudAvailable() {
            // Sync local to cloud
            if localToCloud {
                for (i, k) in keys.enumerated() {
                    switch keyTypes[i] {
                    // Integer
                    case 1:
                        NSUbiquitousKeyValueStore.default.set(UserDefaults.standard.integer(forKey: k), forKey: k)
                    // String
                    case 2:
                        if let value = UserDefaults.standard.string(forKey: k) {
                            NSUbiquitousKeyValueStore.default.set(value, forKey: k)
                        }
                    // Bool
                    default:
                        NSUbiquitousKeyValueStore.default.set(UserDefaults.standard.bool(forKey: k), forKey: k)
                        print("LOCAL 2 CLOUD \(k) \(UserDefaults.standard.bool(forKey: k))")
                    }
                }
                NSUbiquitousKeyValueStore.default.synchronize()
            }
            // Sync cloud to local
            else {
                for (i, k) in keys.enumerated() {
                    switch keyTypes[i] {
                    // Integer
                    case 1:
                        if let value = NSUbiquitousKeyValueStore.default.object(forKey: k) as? Int {
                            UserDefaults.standard.set(value, forKey: k)
                        }
                    // String
                    case 2:
                        if let value = NSUbiquitousKeyValueStore.default.string(forKey: k) {
                            UserDefaults.standard.set(value, forKey: k)
                        }
                    // Bool
                    default:
                        UserDefaults.standard.set(NSUbiquitousKeyValueStore.default.bool(forKey: k), forKey: k)
                        print("CLOUD 2 LOCAL \(k) \(UserDefaults.standard.bool(forKey: k))")
                    }
                }
            }
        }
    }
    
    // Should only ever be called once - used to migrate legacy UserPreferences to UserDefaults and NSUbiquitousKeyValueStore
    public func initialUserPreferencesMigration(existingPreferences: UserPreferences) {
        // App launch skips migration for isolated UI-test storage, but keep the
        // model guard here so direct calls cannot mark real preferences migrated.
        guard persistsPreferenceUpdates else { return }

        UserDefaults.standard.set(existingPreferences.usingMetric, forKey: Preferences.keys[0])
        UserDefaults.standard.set(existingPreferences.displayingMetrics, forKey: Preferences.keys[1])
        UserDefaults.standard.set(existingPreferences.colourChoice, forKey: Preferences.keys[2])
        UserDefaults.standard.set(existingPreferences.largeMetrics, forKey: Preferences.keys[3])
        UserDefaults.standard.set(existingPreferences.sortingChoice, forKey: Preferences.keys[4])
        UserDefaults.standard.set(existingPreferences.deletionConfirmation, forKey: Preferences.keys[5])
        UserDefaults.standard.set(existingPreferences.deletionEnabled, forKey: Preferences.keys[6])
        UserDefaults.standard.set(existingPreferences.namedRoutes, forKey: Preferences.keys[7])
        UserDefaults.standard.set(existingPreferences.selectedRoute, forKey: Preferences.keys[8])
        UserDefaults.standard.set(existingPreferences.autoLockDisabled, forKey: Preferences.keys[9])
        UserDefaults.standard.set(existingPreferences.healthSyncEnabled, forKey: Preferences.keys[10])
        
        UserDefaults.standard.set(existingPreferences.iconIndex, forKey: Preferences.iconIndexKey)
        
        // Default iCloud to OFF
        UserDefaults.standard.set(false, forKey: Preferences.iCloudOnKey)
        
        UserDefaults.standard.set(true, forKey: Preferences.initKey)
        
        self.writeToClassMembers()
    }
    
    // Isolated launch preferences still update published Settings state; only
    // this helper writes the backing stores during persistent app launches.
    private func setPersistentPreference(_ value: Bool, forKey key: String) {
        guard persistsPreferenceUpdates else { return }
        UserDefaults.standard.set(value, forKey: key)
    }

    private func setPersistentPreference(_ value: String, forKey key: String) {
        guard persistsPreferenceUpdates else { return }
        UserDefaults.standard.set(value, forKey: key)
    }

    private func setPersistentPreference(_ value: Int, forKey key: String) {
        guard persistsPreferenceUpdates else { return }
        UserDefaults.standard.set(value, forKey: key)
    }

    private func syncPersistentPreferencesIfNeeded() {
        guard persistsPreferenceUpdates else { return }
        Preferences.syncLocalAndCloud(localToCloud: true)
    }

    // To be called when an update of a preference is needed
    public func updateBoolPreference(preference: CustomizablePreferences, value: Bool) {
        switch preference {
        case .metric:
            setPersistentPreference(value, forKey: Preferences.keys[0])
            self.usingMetric = value
        case .displayingMetrics:
            setPersistentPreference(value, forKey: Preferences.keys[1])
            self.displayingMetrics = value
        case .largeMetrics:
            setPersistentPreference(value, forKey: Preferences.keys[3])
            self.largeMetrics = value
        case .deletionConfirmation:
            setPersistentPreference(value, forKey: Preferences.keys[5])
            self.deletionConfirmation = value
        case .deletionEnabled:
            setPersistentPreference(value, forKey: Preferences.keys[6])
            self.deletionEnabled = value
        case .namedRoutes:
            setPersistentPreference(value, forKey: Preferences.keys[7])
            self.namedRoutes = value
        case .autoLockDisabled:
            setPersistentPreference(value, forKey: Preferences.keys[9])
            self.autoLockDisabled = value
        case .healthSyncEnabled:
            setPersistentPreference(value, forKey: Preferences.keys[10])
            self.healthSyncEnabled = value
        case .autoPauseEnabled:
            setPersistentPreference(value, forKey: Preferences.keys[11])
            self.autoPauseEnabled = value
        case .telemetryEnabled:
            setPersistentPreference(value, forKey: Preferences.telemetryEnabledKey)
            self.telemetryEnabled = value
        case .iCloudSync:
            // Special case for turning on iCloud
            setPersistentPreference(value, forKey: Preferences.iCloudOnKey)
            self.iCloudOn = value
            // Check if iCloud has been setup
            if persistsPreferenceUpdates {
                let status = Preferences.havePreferencesBeenInitialized()
                if (status == 3 && value) {
                    Preferences.syncLocalAndCloud(localToCloud: false)
                    self.writeToClassMembers()
                }
            }
        default:
            fatalError("Incorrect parameter for preference")
        }
        
        // Update iCloud data
        syncPersistentPreferencesIfNeeded()
    }
    
    public func updateStringPreference(preference: CustomizablePreferences, value: String) {
        switch preference {
        case .colour:
            setPersistentPreference(value, forKey: Preferences.keys[2])
            self.colourChoice = value
        case .sortingChoice:
            setPersistentPreference(value, forKey: Preferences.keys[4])
            self.sortingChoice = value
        case .selectedRoute:
            setPersistentPreference(value, forKey: Preferences.keys[8])
            self.selectedRoute = value
        case .mapTypeChoice:
            setPersistentPreference(value, forKey: Preferences.keys[12])
            self.mapTypeChoice = value
        default:
            fatalError("Incorrect parameter for preference")
        }

        // Update iCloud data
        syncPersistentPreferencesIfNeeded()
    }

    public func updateIntPreference(preference: CustomizablePreferences, value: Int) {
        switch preference {
        case .iconIndex:
            setPersistentPreference(value, forKey: Preferences.iconIndexKey)
            self.iconIndex = value
        default:
            fatalError("Incorrect parameter for preference")
        }
    }
    
    // For the reset to default settings button on the settings tab
    public func resetPreferences() {
        if !persistsPreferenceUpdates {
            // Settings UI-smoke tests can tap reset; reset only the selected
            // launch preferences object so production defaults stay untouched.
            resetPreferencesInMemory()
            return
        }

        Preferences.writeDefaults(iCloud: false)
        Preferences.syncLocalAndCloud(localToCloud: true)
        self.writeToClassMembers()
    }

    private func resetPreferencesInMemory() {
        usingMetric = Preferences.defaultUsingMetric
        displayingMetrics = Preferences.defaultDisplayingMetrics
        colourChoice = Preferences.defaultColourChoice
        largeMetrics = Preferences.defaultLargeMetrics
        sortingChoice = Preferences.defaultSortingChoice
        deletionConfirmation = Preferences.defaultDeletionConfirmation
        deletionEnabled = Preferences.defaultDeletionEnabled
        iconIndex = Preferences.defaultIconIndex
        namedRoutes = Preferences.defaultNamedRoutes
        selectedRoute = Preferences.defaultSelectedRoute
        iCloudOn = Preferences.defaultICloudOn
        autoLockDisabled = Preferences.defaultAutoLockDisabled
        healthSyncEnabled = Preferences.defaultHealthSyncEnabled
        autoPauseEnabled = Preferences.defaultAutoPauseEnabled
        telemetryEnabled = Preferences.defaultTelemetryEnabled
        mapTypeChoice = Preferences.defaultMapTypeChoice
    }
    
    // Used in BikeRideViewModel where the environment object is not available
    static func storedSortingChoice() -> SortChoice {
        guard let stringValue = UserDefaults.standard.string(forKey: Preferences.keys[4]) else {
            // UI-smoke tests avoid writing normal defaults; callers still need a
            // stable sort preference when reading outside the environment object.
            return SortChoice.dateDescending
        }
        return SortChoice(rawValue: stringValue) ?? SortChoice.dateDescending
    }
    
    // Used in HealthKitViewModel where the environment object is not available.
    // Isolated UI-test launches must not read the user's real HealthKit setting,
    // because a saved test route could otherwise write production Health samples.
    static func storedHealthSyncEnabled(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> Bool {
        guard !UITesting.shouldUseIsolatedPersistence(arguments: arguments) else {
            return false
        }
        return UserDefaults.standard.bool(forKey: Preferences.keys[10])
    }
    
    static func storedSelectedRoute() -> String {
        // UI-smoke tests avoid writing normal defaults, so missing route selection
        // should mean "all routes" instead of crashing on a force unwrap.
        return UserDefaults.standard.string(forKey: Preferences.keys[8]) ?? ""
    }
}
