//
//  RouteNamingViewModel.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-05-15.
//

import Foundation
import SwiftUI
import CoreData

class RouteNamingViewModel: ObservableObject {

    @Published var allBikeRides: [BikeRide] = []
    @Published var routeNames: [String] = []

    func useBikeRideContext(_ context: NSManagedObjectContext) {
        // Route-naming UI tests present sheets after launch storage selection, so
        // route lists must load from the selected context, not the singleton.
        useBikeRides(BikeRide.allBikeRides(in: context))
    }

    private func useBikeRides(_ bikeRides: [BikeRide]) {
        allBikeRides = bikeRides
        routeNames = BikeRide.allRouteNames(from: bikeRides)
    }
    
}
