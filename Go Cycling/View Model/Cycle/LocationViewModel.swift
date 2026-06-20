//
//  LocationViewModel.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-04-11.
//

import Foundation
import CoreLocation
import Combine

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    // A singleton for the entire app - there should be only 1 instance of this class
    static let locationManager = LocationViewModel()
    
    private let locationManager = CLLocationManager()
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    @Published var cyclingLocations: [CLLocation?] = []
    @Published var cyclingSpeed: CLLocationSpeed?
    @Published var cyclingSpeeds: [CLLocationSpeed?] = []
    @Published var displaySpeed: CLLocationSpeed? = nil
    @Published var autoPauseState: AutoPauseState = .notCycling

    private var stalenessTimer: Timer?
    private var lastLocationUpdateTime: Date = Date()
    private var stoppedSpeedDuration: TimeInterval = 0.0
    // Completed route save tests need callbacks isolated by session because CLLocationManager
    // can deliver old samples or save completions after the next ride starts.
    private var isTrackingCyclingSession = false
    private var cyclingSessionToken = 0
    @Published var cyclingAltitude: CLLocationDistance?
    @Published var cyclingAltitudes: [CLLocationDistance?] = []
    @Published var cyclingDistances: [CLLocationDistance?] = []
    @Published var cyclingTotalDistance: CLLocationDistance = 0.0
    
    // A boolean for whether the location alert should be displayed
    @Published var showLocationSettingsAlert = false
    @Published var locationSettingsAlertMessage = ""
    
    // Need access to health kit manager to update cycling distance
    var healthKitManager = HealthKitManager.healthKitManager
    
    // Track time stamps to update health kit
    var lastHealthLocationTime = Date()
    var writeHealthData = false
    // Send health data in increments of 500 metres
    var lastHealthStoreThreshold = 500.0
    var distanceSinceLastHealthStore = 0.0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = 10
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if UITesting.shouldRequestLocationAuthorization {
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        // Get the initial location settings alert message
        setLocationAlertMessage()
    }
    
    var statusString: String {
        guard let status = locationStatus else {
            return "unknown"
        }
        
        switch status {
        case .notDetermined: return "notDetermined"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        case .authorizedAlways: return "authorizedAlways"
        case .restricted: return "restricted"
        case .denied: return "denied"
        default: return "unknown"
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
        // Update the location settings alert message each time the user changes the authorization status
        setLocationAlertMessage()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError
        // kCLErrorLocationUnknown is transient — location manager will keep trying
        if clError?.code != .locationUnknown {
            print("LocationViewModel didFailWithError: \(error)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        // Completed route save tests need saved routes to contain only active-session
        // samples, so launch-time and post-stop callbacks are ignored.
        guard isTrackingCyclingSession else { return }
        cyclingLocations.append(lastLocation)
        cyclingSpeed = location.speed
        cyclingAltitude = location.altitude
        cyclingSpeeds.append(cyclingSpeed)
        cyclingAltitudes.append(cyclingAltitude)

        lastLocationUpdateTime = Date()
        displaySpeed = location.speed >= 0 ? location.speed : 0
        stoppedSpeedDuration = 0.0

        let speedThreshold: CLLocationSpeed = 0.5
        if location.speed >= speedThreshold && autoPauseState == .stopped {
            autoPauseState = .resumed
        } else if location.speed >= speedThreshold {
            autoPauseState = .moving
        }
        
        // Add location to array
        let locationsCount = cyclingLocations.count
        if (locationsCount > 1) {
            let newDistanceInMeters = lastLocation?.distance(from: (cyclingLocations[locationsCount - 2] ?? lastLocation)!)
            cyclingDistances.append(newDistanceInMeters)
            cyclingTotalDistance += newDistanceInMeters ?? 0.0
            
            // Update health kit data store if enabled
            distanceSinceLastHealthStore += newDistanceInMeters ?? 0.0
            if writeHealthData && distanceSinceLastHealthStore > lastHealthStoreThreshold {
                healthKitManager.writeCyclingDistance(startDate: lastHealthLocationTime, distanceToAdd: distanceSinceLastHealthStore)
                lastHealthLocationTime = Date()
                distanceSinceLastHealthStore = 0.0
            }
        }
    }
    
    // Used to keep the alert message up to date as the authorization status changes
    func setLocationAlertMessage() {
        locationSettingsAlertMessage = LocationSettingsAlertPolicy.alertMessage(
            for: locationStatus ?? .notDetermined
        )
    }
    
    // Used to decide whether to show a location settings alert when the user starts a session
    func setLocationAlertStatus() {
        if UITesting.shouldUseCycleControlsFixture() && locationSettingsAlertMessage.isEmpty {
            // The Cycle controls UI test needs a deterministic alert to exercise
            // alert action identifiers even on simulators with Always access.
            locationSettingsAlertMessage = LocationSettingsAlertPolicy.alertMessage(for: .denied)
        }
        if (locationSettingsAlertMessage != "") {
            showLocationSettingsAlert = true
        }
    }
    
    func startedCycling() {
        // Completed route save tests need a new ride to invalidate any previous async save
        // cleanup/naming before this ride starts collecting samples.
        cyclingSessionToken += 1
        isTrackingCyclingSession = true
        // Setup background location checking if authorized
        if locationStatus == .authorizedAlways {
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.allowsBackgroundLocationUpdates = true
        }
        // Clear all pre-ride locations so the route starts from the actual ride start
        cyclingLocations.removeAll()
        // Clear all distances
        cyclingDistances.removeAll()
        cyclingSpeeds.removeAll()
        cyclingAltitudes.removeAll()
        cyclingTotalDistance = 0.0
        
        // Start writing health data if the setting is enabled
        lastHealthLocationTime = Date()
        distanceSinceLastHealthStore = 0.0
        writeHealthData = Preferences.storedHealthSyncEnabled()

        locationManager.startUpdatingHeading()
        // The Cycle controls fixture suppresses staleness auto-pause so the UI
        // test can assert Pause/Resume identifiers without a timer race.
        if !UITesting.shouldUseCycleControlsFixture() {
            stalenessTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.handleStalenessTick()
            }
        }
        if UITesting.shouldUseAutoPauseFixture() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self, self.isTrackingCyclingSession else { return }
                self.autoPauseState = .stopped
            }
        }
        autoPauseState = .moving
    }

    var currentCyclingSessionToken: Int {
        cyclingSessionToken
    }

    func isCurrentCyclingSession(_ token: Int) -> Bool {
        // Completed route save tests use this check to prove an old async save cannot clear
        // or name a newer ride that has already started.
        cyclingSessionToken == token
    }
    
    private func handleStalenessTick() {
        let elapsed = Date().timeIntervalSince(lastLocationUpdateTime)
        if elapsed >= 5.0 {
            displaySpeed = 0
            stoppedSpeedDuration += 1.0
            if stoppedSpeedDuration >= 3.0 && autoPauseState == .moving {
                autoPauseState = .stopped
            }
        }
    }

    // Called on manual resume so auto-pause can re-trigger if the user remains stopped.
    // Set to -5 instead of 0 so the re-trigger window feels the same as the initial auto-pause
    // (~8s total vs 3s). Safe to use a negative value since didUpdateLocations resets this to 0
    // on every GPS update, so it self-corrects the moment the user starts moving.
    func resetStalenessDuration() {
        stoppedSpeedDuration = -5.0
    }

    // Completed route save tests need live-session side effects stopped immediately while
    // samples are kept until persistence succeeds, so failed saves are recoverable.
    func endCyclingSession() {
        isTrackingCyclingSession = false
        stalenessTimer?.invalidate()
        stalenessTimer = nil
        locationManager.stopUpdatingHeading()
        displaySpeed = nil
        autoPauseState = .notCycling
        stoppedSpeedDuration = 0.0

        // Store the last health kit data point if enabled
        // Only store the data point if the user has moved more than 1 metre
        if writeHealthData && distanceSinceLastHealthStore > 0.9 {
            healthKitManager.writeCyclingDistance(startDate: lastHealthLocationTime, distanceToAdd: distanceSinceLastHealthStore)
        }
        
        // Stop writing health data
        writeHealthData = false
        distanceSinceLastHealthStore = 0.0
    }

    func clearCompletedRouteData() {
        // Completed route save tests call this only after successful async persistence so
        // the user does not lose unsaved samples when a save fails.
        cyclingLocations.removeAll()
        cyclingDistances.removeAll()
        cyclingSpeeds.removeAll()
        cyclingAltitudes.removeAll()
        cyclingTotalDistance = 0.0
    }
    
    func stopTrackingBackgroundLocation() {
        // There is no reason to allow background location updates if the user is not actively cycling
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = false
    }
}
