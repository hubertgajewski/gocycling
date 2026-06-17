//
//  CompletedRouteSaveCoordinator.swift
//  Go Cycling
//

import CoreLocation
import Foundation

struct CompletedRouteSnapshot {
    let locations: [CLLocation?]
    let speeds: [CLLocationSpeed?]
    let distance: Double
    let elevations: [CLLocationDistance?]
    let startTime: Date
    let time: Double
}

protocol BikeRideStoring {
    func storeBikeRide(
        locations: [CLLocation?],
        speeds: [CLLocationSpeed?],
        distance: Double,
        elevations: [CLLocationDistance?],
        startTime: Date,
        time: Double,
        completion: @escaping () -> Void
    )
}

protocol CyclingRecordsUpdating {
    func updateCyclingRecords(
        speeds: [CLLocationSpeed?],
        distance: Double,
        startTime: Date,
        time: Double
    )
}

struct CompletedRouteSaveCoordinator {
    let persistenceController: BikeRideStoring
    let records: CyclingRecordsUpdating

    func save(
        _ completedRoute: CompletedRouteSnapshot,
        cleanup: @escaping () -> Void = {},
        completion: @escaping () -> Void = {}
    ) {
        persistenceController.storeBikeRide(
            locations: completedRoute.locations,
            speeds: completedRoute.speeds,
            distance: completedRoute.distance,
            elevations: completedRoute.elevations,
            startTime: completedRoute.startTime,
            time: completedRoute.time
        ) {
            records.updateCyclingRecords(
                speeds: completedRoute.speeds,
                distance: completedRoute.distance,
                startTime: completedRoute.startTime,
                time: completedRoute.time
            )
            cleanup()
            completion()
        }
    }
}

extension PersistenceController: BikeRideStoring {}

extension CyclingRecords: CyclingRecordsUpdating {}
