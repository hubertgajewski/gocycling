//
//  MapView.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-04-09.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    typealias UIViewType = MKMapView
    
    let persistenceController = PersistenceController.shared

    @EnvironmentObject var cyclingStatus: CyclingStatus
    
    @StateObject var locationManager = LocationViewModel.locationManager
    
    @Binding var centerMapOnLocation: Bool
    @Binding var cyclingStartTime: Date
    @Binding var timeCycling: TimeInterval
    // Route-naming UI tests need the exact saved BikeRide because History ordering
    // can change while the async save finishes.
    var onRouteSaveSuccess: (BikeRide) -> Void = { _ in }
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject var preferences: Preferences
    @EnvironmentObject var records: CyclingRecords
    
    var userLatitude: String {
        return "\(locationManager.lastLocation?.coordinate.latitude ?? 0)"
    }
        
    var userLongitude: String {
        return "\(locationManager.lastLocation?.coordinate.longitude ?? 0)"
    }
    
    func makeCoordinator() -> MapView.Coordinator {
        Coordinator(self, colour: UserPreferences.convertColourChoiceToUIColor(colour: preferences.colourChoiceConverted))
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var control: MapView
        var colour: UIColor
        var currentRouteOverlay: MKPolyline?
        var lastRenderedCount: Int = 0

        init(_ control: MapView, colour: UIColor) {
            self.control = control
            self.colour = colour
        }

        //Managing the Display of Overlays
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let polylineRenderer = MKPolylineRenderer(overlay: polyline)
                polylineRenderer.strokeColor = colour
                polylineRenderer.lineWidth = 8
                return polylineRenderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        // UI-smoke tests are not testing permissions here; hiding user location
        // avoids MKMapView permission UI that can block the tab smoke flow.
        mapView.showsUserLocation = UITesting.shouldShowUserLocation
        mapView.showsCompass = false
        mapView.mapType = preferences.mapTypeChoiceConverted.mkMapType
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        let preferredMapType = preferences.mapTypeChoiceConverted.mkMapType
        if view.mapType != preferredMapType {
            view.mapType = preferredMapType
        }

        let authStatus = locationManager.statusString
        let isLocationAuthorized = authStatus == "authorizedAlways" || authStatus == "authorizedWhenInUse"

        if UITesting.shouldShowUserLocation && isLocationAuthorized {
            if centerMapOnLocation {
                if view.userTrackingMode != .followWithHeading {
                    view.setUserTrackingMode(.followWithHeading, animated: true)
                }
            } else {
                if view.userTrackingMode == .followWithHeading {
                    view.setUserTrackingMode(.none, animated: false)
                }
            }
        }

        if isLocationAuthorized {
            // Need to maintain the cyclists route if they are currently cycling
            if cyclingStatus.isCycling {
                if (!startedCycling) {
                    startedCycling = true
                    // Route-save UI tests need the new ride to start from a clean
                    // map; SwiftUI can redraw before new GPS samples arrive.
                    context.coordinator.currentRouteOverlay = nil
                    context.coordinator.lastRenderedCount = 0
                    view.removeOverlays(view.overlays)
                } else {
                    let locationsCount = locationManager.cyclingLocations.count
                    // Only rebuild the overlay when new locations have arrived
                    if locationsCount >= 2 && locationsCount != context.coordinator.lastRenderedCount {
                        let coords = locationManager.cyclingLocations.compactMap { $0?.coordinate }
                        if coords.count > 1 {
                            // Remove the single existing overlay and replace with one updated overlay
                            if let old = context.coordinator.currentRouteOverlay {
                                view.removeOverlay(old)
                            }
                            let route = MKPolyline(coordinates: coords, count: coords.count)
                            context.coordinator.currentRouteOverlay = route
                            context.coordinator.lastRenderedCount = coords.count
                            view.addOverlay(route)

                            // Update stroke colour if user changes colour preference after renderer was created
                            if let renderer = view.renderer(for: route) as? MKPolylineRenderer {
                                let preferredColor = UserPreferences.convertColourChoiceToUIColor(colour: preferences.colourChoiceConverted)
                                if renderer.strokeColor != preferredColor {
                                    renderer.strokeColor = preferredColor
                                }
                            }
                        }
                    }
                }
            }
            else {
                // Means we need to store the current route and clear the map
                if (startedCycling) {
                    startedCycling = false
                    // Route-save tests need a stale save completion blocked from
                    // clearing or naming a new ride that has already started.
                    let completedSessionToken = locationManager.currentCyclingSessionToken
                    // Route-save tests need an immutable copy before end-of-ride
                    // cleanup stops live state and arrays can be cleared.
                    let completedRoute = CompletedRouteSnapshot(
                        locations: locationManager.cyclingLocations,
                        speeds: locationManager.cyclingSpeeds,
                        distance: locationManager.cyclingTotalDistance,
                        elevations: locationManager.cyclingAltitudes,
                        startTime: cyclingStartTime,
                        time: timeCycling
                    )
                    locationManager.endCyclingSession()
                    locationManager.stopTrackingBackgroundLocation()
                    CompletedRouteSaveCoordinator(
                        persistenceController: persistenceController,
                        records: records
                    ).save(completedRoute, cleanupAfterSuccess: {
                        // Route-save tests cover stale completions; ignoring old
                        // sessions prevents removing overlay/samples for the next ride.
                        guard locationManager.isCurrentCyclingSession(completedSessionToken) else { return }
                        context.coordinator.currentRouteOverlay = nil
                        context.coordinator.lastRenderedCount = 0
                        view.removeOverlays(view.overlays)
                        locationManager.clearCompletedRouteData()
                    }, completion: { result in
                        // Route-naming UI tests cover stale completions; only this
                        // completed session may open the sheet for its saved route.
                        guard locationManager.isCurrentCyclingSession(completedSessionToken) else { return }
                        if case .success(let savedRide) = result {
                            onRouteSaveSuccess(savedRide)
                        }
                    })
                }
            }
        }
    }
}

var startedCycling = false

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(centerMapOnLocation: .constant(true), cyclingStartTime: .constant(Date()), timeCycling: .constant(10))
    }
}
