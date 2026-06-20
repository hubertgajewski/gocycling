/// UI-test mirror of app-owned accessibility identifiers.
///
/// UI tests are black-box and cannot import the app target's helpers. Cycle
/// and Settings reset values mirror `Go Cycling/Support/UITesting.swift`;
/// main-tab values mirror the root tab identifiers set in the tab views.
enum AccessibilityID {
  enum MainTab {
    static let cycleContent = "main-tab-cycle"
    static let historyContent = "main-tab-history"
    static let statisticsContent = "main-tab-statistics"
    static let settingsContent = "main-tab-settings"
  }

  enum Cycle {
    static let timerDisplay = "cycle-timer-display"
    static let mapLockButton = "cycle-map-lock-button"
    static let mapUnlockButton = "cycle-map-unlock-button"
    static let startButton = "cycle-start-button"
    static let pauseButton = "cycle-pause-button"
    static let resumeButton = "cycle-resume-button"
    static let stopButton = "cycle-stop-button"
    static let locationSettingsOpenSettingsButton =
      "cycle-location-settings-open-settings-button"
    static let locationSettingsIgnoreButton = "cycle-location-settings-ignore-button"
    static let stopConfirmationStopButton = "cycle-stop-confirmation-stop-button"
    static let stopConfirmationCancelButton = "cycle-stop-confirmation-cancel-button"
  }

  enum SettingsReset {
    static let deleteAllRoutesButton = "settings-reset-delete-all-routes-button"
    static let resetStatisticsButton = "settings-reset-stored-statistics-button"
    static let resetDefaultSettingsButton = "settings-reset-default-settings-button"
  }

  enum History {
    static let emptyState = "history-empty-state"
  }
}
