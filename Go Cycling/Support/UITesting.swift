//
//  UITesting.swift
//  Go Cycling
//

import Foundation

enum UITesting {
    // UI tests stay black-box so they cannot link app-only helper code; raw
    // launch strings are the stable contract between test target and app.
    // Cycle controls UI tests need deterministic alerts and timer behavior
    // without applying those fixtures to every UI-testing launch.
    static let cycleControlsFixtureArgument = "-ui-testing-cycle-controls-fixture"
    static let autoPauseFixtureArgument = "-ui-testing-auto-pause-fixture"
    static let skipReviewPromptArgument = "-ui-testing-skip-review-prompt"

    #if DEBUG
    static func shouldSkipReviewPrompt(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        arguments.contains(skipReviewPromptArgument)
    }

    static func shouldUseCycleControlsFixture(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        arguments.contains(cycleControlsFixtureArgument)
    }

    static func shouldUseAutoPauseFixture(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        arguments.contains(autoPauseFixtureArgument)
    }
    #else
    static func shouldSkipReviewPrompt(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        false
    }

    static func shouldUseCycleControlsFixture(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        false
    }

    static func shouldUseAutoPauseFixture(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        false
    }
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
        static let autoPausedBanner = "cycle-auto-paused-banner"
        static let metricsPill = "cycle-metrics-pill"
        static let metricsSpeedValue = "cycle-metrics-speed-value"
        static let metricsDistanceValue = "cycle-metrics-distance-value"
        static let metricsAltitudeValue = "cycle-metrics-altitude-value"
        static let mapView = "cycle-map-view"
    }

    enum RouteCategorization {
        static let title = "route-categorization-title"
        static let createNewCategorySegment = "route-categorization-create-new-segment"
        static let useExistingCategorySegment = "route-categorization-use-existing-segment"
        static let categoryNameField = "route-categorization-category-name-field"
        static let saveButton = "route-categorization-save-button"
        static let saveWithoutCategoryButton = "route-categorization-save-without-category-button"
        static let existingCategoryRowPrefix = "route-categorization-existing-row-"
    }

    enum History {
        static let emptyState = "history-empty-state"
        static let rideRow = "history-ride-row"
    }

    enum Statistics {
        static let cyclingChartsSection = "statistics-section-cycling-charts"
        static let cyclingRecordsSection = "statistics-section-cycling-records"
        static let activityAwardsSection = "statistics-section-activity-awards"
        static let chartsFooter = "statistics-charts-footer"
        static let recordsFooter = "statistics-records-footer"
        static let awardsFooter = "statistics-awards-footer"
        static let singleRouteRecordsHeader = "statistics-single-route-records-header"
        static let cumulativeRecordsHeader = "statistics-cumulative-records-header"

        static let chartPeriod7Days = "statistics-chart-period-7-days"
        static let chartPeriod5Weeks = "statistics-chart-period-5-weeks"
        static let chartPeriod30Weeks = "statistics-chart-period-30-weeks"

        static let recordLongestDistance = "statistics-record-longest-distance"
        static let recordLongestTime = "statistics-record-longest-time"
        static let recordBestSpeed = "statistics-record-best-speed"
        static let recordTotalDistance = "statistics-record-total-distance"
        static let recordTotalTime = "statistics-record-total-time"
        static let recordTotalRoutes = "statistics-record-total-routes"

        static let awardRow = "statistics-award-row"
        static let awardProgress = "statistics-award-progress"

        static let chartPeriodIdentifiers = [
            chartPeriod7Days,
            chartPeriod5Weeks,
            chartPeriod30Weeks,
        ]
    }

    enum Settings {
        static let customizationSection = "settings-section-customization"
        static let cyclingMetricsSection = "settings-section-cycling-metrics"
        static let cyclingHistorySection = "settings-section-cycling-history"
        static let cyclingSection = "settings-section-cycling"
        static let syncSection = "settings-section-sync"
        static let aboutSection = "settings-section-about"
        static let supportSection = "settings-section-support"
        static let resetSection = "settings-section-reset"
        static let privacySection = "settings-section-privacy"
        static let privacyFooter = "settings-privacy-footer"

        static let colourPicker = "settings-colour-picker"
        static let appIconPicker = "settings-app-icon-picker"
        static let preferredUnitsLabel = "settings-preferred-units-label"
        static let preferredUnitsPicker = "settings-preferred-units-picker"
        static let displayMetricsOnMap = "settings-display-metrics-on-map"
        static let mapTypePicker = "settings-map-type-picker"
        static let routeCategorizationEnabled = "settings-route-categorization-enabled"
        static let deletionEnabled = "settings-deletion-enabled"
        static let deletionConfirmationAlert = "settings-deletion-confirmation-alert"
        static let disableAutoLock = "settings-disable-auto-lock"
        static let autoPauseWhenStopped = "settings-auto-pause-when-stopped"
        static let iCloudSync = "settings-icloud-sync"
        static let iCloudTitle = "settings-icloud-title"
        static let iCloudSubtitle = "settings-icloud-subtitle"
        static let healthSync = "settings-health-sync"
        static let healthTitle = "settings-health-title"
        static let healthSubtitle = "settings-health-subtitle"
        static let appVersionLabel = "settings-app-version-label"
        static let appVersionValue = "settings-app-version-value"
        static let openSource = "settings-open-source"
        static let share = "settings-share"
        static let review = "settings-review"
        static let privacyPolicy = "settings-privacy-policy"
        static let termsAndConditions = "settings-terms-and-conditions"
        static let shareAnonymousAnalytics = "settings-share-anonymous-analytics"
        static let deleteAllRoutesButton = "settings-reset-delete-all-routes-button"
        static let resetStatisticsButton = "settings-reset-stored-statistics-button"
        static let resetDefaultSettingsButton = "settings-reset-default-settings-button"
    }
}
