//
//  ContentView.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-03-14.
//

import SwiftUI

struct CycleView: View {
    
    @EnvironmentObject var cyclingStatus: CyclingStatus
    
    @StateObject var timer = TimerViewModel()
    @State private var showingAlert = false
    @State private var cyclingSpeed = 0.0
    @State private var cyclingStartTime = Date()
    @State private var timeCycling = 0.0
    @State private var showingRouteNamingPopover = false
    // Route naming needs the exact saved ride from the async save so the sheet
    // does not have to guess via the current History ordering.
    @State private var savedRouteForNaming: BikeRide?
    @State private var isAutoPaused: Bool = false
    
    @StateObject var locationManager = LocationViewModel.locationManager
    
    @EnvironmentObject var preferences: Preferences
    
    let telemetryManager = TelemetryManager.sharedTelemetryManager
    let telemetryTab = TelemetryTab.Cycle
    
    var body: some View {
        GeometryReader { (geometry) in
            VStack {
                MapWithSpeedView(
                    cyclingStartTime: $cyclingStartTime,
                    timeCycling: $timeCycling,
                    onRouteSaveSuccess: routeSaved
                )
                .layoutPriority(1)
                .cycleLocationSettingsAlert(
                    isPresented: $locationManager.showLocationSettingsAlert,
                    message: locationManager.locationSettingsAlertMessage,
                    openSettings: openLocationSettings
                )
                VStack(spacing: 4) {
                    // UI tests assert Cycle state through stable identifiers
                    // instead of localized text, formatting, or SF Symbol names.
                    Text(MetricsFormatting.formatElapsedTimer(time: timer.totalAccumulatedTime))
                        .font(.custom("Avenir", size: 40))
                        .accessibilityIdentifier(AccessibilityIdentifier.Cycle.timerDisplay)
                    if isAutoPaused {
                        HStack(spacing: 6) {
                            Spacer(minLength: 0)
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("Auto-Paused")
                                .font(.system(size: 14, weight: .bold))
                            Spacer(minLength: 0)
                        }
                        .foregroundColor(Color(.systemYellow))
                        .padding(.vertical, 12)
                        .background(Color(.systemYellow).opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(.systemYellow), lineWidth: 1.5))
                        .padding(.horizontal, 24)
                        .accessibilityIdentifier(AccessibilityIdentifier.Cycle.autoPausedBanner)
                    }
                }
                Spacer()
                HStack(spacing: 16) {
                    if timer.isRunning {
                        Button(action: { self.pauseCycling() }) {
                            TimerButton(label: "Pause", buttonColour: UIColor.systemYellow, systemImageName: "pause.fill", expandsHorizontally: true)
                        }
                        .accessibilityIdentifier(AccessibilityIdentifier.Cycle.pauseButton)
                        Button(action: { self.confirmStop() }) {
                            TimerButton(label: "Stop", buttonColour: UIColor.systemRed, isSecondary: true, systemImageName: "stop.fill")
                        }
                        .accessibilityIdentifier(AccessibilityIdentifier.Cycle.stopButton)
                    }
                    if timer.isStopped {
                        Button(action: { self.startCycling() }) {
                            TimerButton(label: "Start", buttonColour: UIColor.systemGreen, systemImageName: "play.fill", expandsHorizontally: true)
                        }
                        .accessibilityIdentifier(AccessibilityIdentifier.Cycle.startButton)
                    }
                    if timer.isPaused {
                        Button(action: { self.resumeCycling() }) {
                            TimerButton(label: "Resume", buttonColour: UIColor.systemGreen, systemImageName: "play.fill", expandsHorizontally: true)
                        }
                        .accessibilityIdentifier(AccessibilityIdentifier.Cycle.resumeButton)
                        Button(action: { self.confirmStop() }) {
                            TimerButton(label: "Stop", buttonColour: UIColor.systemRed, isSecondary: true, systemImageName: "stop.fill")
                        }
                        .accessibilityIdentifier(AccessibilityIdentifier.Cycle.stopButton)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .cycleStopConfirmationAlert(
                    isPresented: $showingAlert,
                    confirmStop: stopCyclingAfterConfirmation
                )
                Spacer()
            }
            .sheet(isPresented: $showingRouteNamingPopover) {
                RouteNameModalView(
                    showEditModal: $showingRouteNamingPopover,
                    bikeRideToEdit: nil,
                    bikeRideToName: savedRouteForNaming
                )
            }
            .onChange(of: locationManager.autoPauseState) { state in
                guard preferences.autoPauseEnabled else { return }
                switch state {
                case .stopped:
                    if !isAutoPaused && timer.isRunning {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            pauseCycling()
                            isAutoPaused = true
                        }
                    }
                case .resumed:
                    if isAutoPaused {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            resumeCycling()
                            isAutoPaused = false
                        }
                        locationManager.autoPauseState = .moving
                    }
                default:
                    break
                }
            }
        }
    }
    
    func startCycling() {
        // Send an alert about location settings if it is necessary
        locationManager.setLocationAlertStatus()
        // Completed route save tests need a fresh session to ignore any prior saved ride if
        // the old naming sheet was dismissed or a late callback arrives.
        savedRouteForNaming = nil
        cyclingStatus.startedCycling()
        // Call synchronously before any SwiftUI re-renders so the pre-ride
        // location/distance data is already cleared when MapView first draws the route
        locationManager.startedCycling()
        self.cyclingStartTime = Date()
        self.timeCycling = 0.0
        self.timer.start()
        
        telemetryManager.sendCyclingSignal(
            tab: telemetryTab,
            action: TelemetryCyclingAction.Start
        )
    }

    // Extracted so the iOS 15 alert buttons can carry UI-test identifiers while
    // sharing the same production action with the iOS 14 Alert fallback.
    func openLocationSettings() {
        // Pause the current cycling session
        self.timer.pause()
        // Open Settings app
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
    
    func pauseCycling() {
        self.timer.pause()
        
        telemetryManager.sendCyclingSignal(
            tab: telemetryTab,
            action: TelemetryCyclingAction.Pause
        )
    }
    
    func resumeCycling() {
        isAutoPaused = false
        locationManager.autoPauseState = .moving
        locationManager.resetStalenessDuration()
        self.timer.start()
        
        telemetryManager.sendCyclingSignal(
            tab: telemetryTab,
            action: TelemetryCyclingAction.Resume
        )
    }
    
    func confirmStop() {
        self.timer.pause()
        showingAlert = true
        
        telemetryManager.sendCyclingSignal(
            tab: telemetryTab,
            action: TelemetryCyclingAction.Stop
        )
    }

    // Extracted so the identifier-bearing stop-confirmation alert and the
    // iOS 14 Alert fallback cannot drift in their route-ending behavior.
    func stopCyclingAfterConfirmation() {
        // Completing a route is a review worthy event
        ReviewManager.incrementReviewWorthyCount()
        // Keep track of whether user has completed a route
        ReviewManager.completedRoute()

        self.isAutoPaused = false
        self.timeCycling = timer.totalAccumulatedTime
        self.timer.stop()
        cyclingStatus.stoppedCycling()

        telemetryManager.sendCyclingSignal(
            tab: telemetryTab,
            action: TelemetryCyclingAction.ConfirmStop
        )
    }

    func routeSaved(_ bikeRide: BikeRide) {
        // Route naming needs the sheet shown only after Core Data returns this
        // saved ride; presenting earlier can rename the wrong route.
        guard preferences.namedRoutes else { return }
        savedRouteForNaming = bikeRide
        showingRouteNamingPopover = true
    }
}

struct CycleView_Previews: PreviewProvider {
    static var previews: some View {
        CycleView()
    }
}

// UI tests need identifiers on alert actions. The iOS 15 alert builder exposes
// Button views that can carry identifiers; the legacy Alert fallback preserves
// iOS 14 behavior where those identifiers cannot be attached.
private extension View {
    @ViewBuilder
    func cycleLocationSettingsAlert(
        isPresented: Binding<Bool>,
        message: String,
        openSettings: @escaping () -> Void
    ) -> some View {
        if #available(iOS 15.0, *) {
            alert(CycleAlertCopy.locationSettingsTitle, isPresented: isPresented) {
                Button(CycleAlertCopy.openSettingsButton, action: openSettings)
                    .accessibilityIdentifier(AccessibilityIdentifier.Cycle.locationSettingsOpenSettingsButton)
                Button(CycleAlertCopy.ignoreButton, role: .cancel) { }
                    .accessibilityIdentifier(AccessibilityIdentifier.Cycle.locationSettingsIgnoreButton)
            } message: {
                Text(message)
            }
        } else {
            // Alert about visiting settings if location access is not allowed
            alert(isPresented: isPresented) {
                Alert(title: Text(CycleAlertCopy.locationSettingsTitle),
                      message: Text(message),
                      primaryButton: .default(Text(CycleAlertCopy.openSettingsButton), action: openSettings),
                      secondaryButton: .cancel(Text(CycleAlertCopy.ignoreButton))
                )
            }
        }
    }

    @ViewBuilder
    func cycleStopConfirmationAlert(
        isPresented: Binding<Bool>,
        confirmStop: @escaping () -> Void
    ) -> some View {
        if #available(iOS 15.0, *) {
            alert(CycleAlertCopy.stopConfirmationTitle, isPresented: isPresented) {
                Button(CycleAlertCopy.stopButton, role: .destructive, action: confirmStop)
                    .accessibilityIdentifier(AccessibilityIdentifier.Cycle.stopConfirmationStopButton)
                Button(CycleAlertCopy.cancelButton, role: .cancel) { }
                    .accessibilityIdentifier(AccessibilityIdentifier.Cycle.stopConfirmationCancelButton)
            } message: {
                Text(CycleAlertCopy.stopConfirmationMessage)
            }
        } else {
            // Confirmation alert about ending the current route
            alert(isPresented: isPresented) {
                Alert(title: Text(CycleAlertCopy.stopConfirmationTitle),
                      message: Text(CycleAlertCopy.stopConfirmationMessage),
                      primaryButton: .destructive(Text(CycleAlertCopy.stopButton), action: confirmStop),
                      secondaryButton: .cancel(Text(CycleAlertCopy.cancelButton))
                )
            }
        }
    }
}

// Shared by the iOS 15 identifier-bearing alerts and the iOS 14 Alert fallback
// so UI-test support does not create separate user-facing copy paths.
private enum CycleAlertCopy {
    static let locationSettingsTitle = "Location settings may not be correct"
    static let openSettingsButton = "Open Settings"
    static let ignoreButton = "Ignore"
    static let stopConfirmationTitle = "Are you sure that you want to end the current route?"
    static let stopConfirmationMessage = "Please confirm that you are ready to end the current route."
    static let stopButton = "Stop"
    static let cancelButton = "Cancel"
}
