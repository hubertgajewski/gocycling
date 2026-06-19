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
        // Naming sheets are presented after launch storage selection, so their
        // route list must be loaded from the selected context, not the singleton.
        useBikeRides(BikeRide.allBikeRides(in: context))
    }

    private func useBikeRides(_ bikeRides: [BikeRide]) {
        allBikeRides = bikeRides
        routeNames = BikeRide.allRouteNames(from: bikeRides)
    }
    
}
