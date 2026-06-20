//
//  MapWithSpeedView.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-04-15.
//

import SwiftUI
import CoreLocation

struct MapWithSpeedView: View {

    @EnvironmentObject var cyclingStatus: CyclingStatus

    @Binding var cyclingStartTime: Date
    @Binding var timeCycling: TimeInterval
    // Route naming needs the exact saved ride forwarded because fetching
    // "latest" can choose the wrong route when saves finish close together.
    var onRouteSaveSuccess: (BikeRide) -> Void = { _ in }

    @StateObject var locationManager = LocationViewModel.locationManager
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var preferences: Preferences

    @State var mapCentered: Bool = true

    var body: some View {
        ZStack {
            MapView(
                centerMapOnLocation: $mapCentered,
                cyclingStartTime: $cyclingStartTime,
                timeCycling: $timeCycling,
                onRouteSaveSuccess: onRouteSaveSuccess
            )
            VStack {
                MetricsPillView(
                    currentSpeed: $locationManager.displaySpeed,
                    currentAltitude: $locationManager.cyclingAltitude,
                    currentDistance: $locationManager.cyclingTotalDistance,
                    pillColor: Color(UserPreferences.convertColourChoiceToUIColor(colour: preferences.colourChoiceConverted))
                )
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        if (mapCentered) {
                            Button (action: {self.toggleMapCentered()}) {
                                MapSystemImageButton(systemImageString: "lock", buttonColour: (UserPreferences.convertColourChoiceToUIColor(colour: preferences.colourChoiceConverted)))
                                    .padding(.bottom, 5)
                                }
                            .accessibilityIdentifier(AccessibilityIdentifier.Cycle.mapLockButton)
                        }
                        else {
                            Button (action: {self.toggleMapCentered()}) {
                                MapSystemImageButton(systemImageString: "lock.open", buttonColour: (UserPreferences.convertColourChoiceToUIColor(colour: preferences.colourChoiceConverted)))
                                    .padding(.bottom, 5)
                                }
                            .accessibilityIdentifier(AccessibilityIdentifier.Cycle.mapUnlockButton)
                        }
                    }
                    Spacer()
                }
            }
        }
        // Container identifier for tab readiness; .contain keeps child control IDs
        // (metrics pill, map lock) visible to XCUITest and VoiceOver.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("main-tab-cycle")
    }

    func toggleMapCentered() {
        self.mapCentered = self.mapCentered ? false : true
    }
}

struct MapWithSpeedView_Previews: PreviewProvider {
    static var previews: some View {
        MapWithSpeedView(cyclingStartTime: .constant(Date()), timeCycling: .constant(10))
    }
}
