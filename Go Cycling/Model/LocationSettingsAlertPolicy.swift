//
//  LocationSettingsAlertPolicy.swift
//  Go Cycling
//

import CoreLocation

// Kept outside LocationViewModel so the alert copy policy is covered without
// constructing CLLocationManager or touching live authorization state.
enum LocationSettingsAlertPolicy {
    static func alertMessage(for status: CLAuthorizationStatus) -> String {
        let messageIfAllowedWhileInUse =
        """
        Go Cycling requires your location to be set to "Always" to function while the app is not on the screen.
        
        Please visit your app settings and verify that location access is allowed.
        
        If you plan to leave your device screen on while cycling then your current location access will work.
        """
        
        let messageIfNotAllowed =
        """
        Go Cycling requires location permissions to track your cycling routes.
        
        Please visit your app settings and verify that location access is allowed.
        
        All of your location data will be stored solely on your device and will never be shared with anyone.
        """
        
        switch status {
            case .authorizedAlways: return ""
            case .authorizedWhenInUse: return messageIfAllowedWhileInUse
            default: return messageIfNotAllowed
        }
    }
}
