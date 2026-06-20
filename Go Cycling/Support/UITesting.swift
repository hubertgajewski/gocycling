//
//  UITesting.swift
//  Go Cycling
//

import Foundation

enum UITesting {
    // UI tests stay black-box so they cannot link app-only helper code; raw
    // launch strings are the stable contract between test target and app.
    static let launchArgument = "-ui-testing"
    // Cycle controls UI tests need deterministic alerts and timer behavior
    // without applying those fixtures to every UI-testing launch.
    static let cycleControlsFixtureArgument = "-ui-testing-cycle-controls-fixture"

    #if DEBUG
    /// True when the app was launched with `-ui-testing` (location/map seams only).
    static func isEnabled(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        arguments.contains(launchArgument)
    }

    static func shouldUseCycleControlsFixture(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        arguments.contains(cycleControlsFixtureArgument)
    }

    static var shouldRequestLocationAuthorization: Bool {
        !isEnabled()
    }

    static var shouldShowUserLocation: Bool {
        !isEnabled()
    }
    #else
    static func isEnabled(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        false
    }

    static func shouldUseCycleControlsFixture(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        false
    }

    static var shouldRequestLocationAuthorization: Bool { true }

    static var shouldShowUserLocation: Bool { true }
    #endif
}

// Black-box UI tests can only find controls through the rendered app process,
// so app code owns these stable identifiers and the test target mirrors them.
enum AccessibilityIdentifier {
    enum Cycle {
        static let timerDisplay = "cycle-timer-display"
        static let mapLockButton = "cycle-map-lock-button"
        static let mapUnlockButton = "cycle-map-unlock-button"
        static let startButton = "cycle-start-button"
        static let pauseButton = "cycle-pause-button"
        static let resumeButton = "cycle-resume-button"
        static let stopButton = "cycle-stop-button"
        static let locationSettingsOpenSettingsButton = "cycle-location-settings-open-settings-button"
        static let locationSettingsIgnoreButton = "cycle-location-settings-ignore-button"
        static let stopConfirmationStopButton = "cycle-stop-confirmation-stop-button"
        static let stopConfirmationCancelButton = "cycle-stop-confirmation-cancel-button"
    }

    enum SettingsReset {
        static let deleteAllRoutesButton = "settings-reset-delete-all-routes-button"
        static let resetStatisticsButton = "settings-reset-stored-statistics-button"
        static let resetDefaultSettingsButton = "settings-reset-default-settings-button"
    }
}
