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
    /// Implementations should call completion on the main queue. The coordinator
    /// defensively hops to main before mutating UI-facing records or cleanup state.
    func storeBikeRide(
        locations: [CLLocation?],
        speeds: [CLLocationSpeed?],
        distance: Double,
        elevations: [CLLocationDistance?],
        startTime: Date,
        time: Double,
        completion: @escaping (Result<BikeRide, Error>) -> Void
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

    init(
        persistenceController: BikeRideStoring = PersistenceController.shared,
        records: CyclingRecordsUpdating = CyclingRecords.shared
    ) {
        self.persistenceController = persistenceController
        self.records = records
    }

    func save(
        _ completedRoute: CompletedRouteSnapshot,
        cleanupAfterSuccess: @escaping () -> Void = {},
        alwaysCleanup: @escaping () -> Void = {},
        completion: @escaping (Result<BikeRide, Error>) -> Void = { _ in }
    ) {
        persistenceController.storeBikeRide(
            locations: completedRoute.locations,
            speeds: completedRoute.speeds,
            distance: completedRoute.distance,
            elevations: completedRoute.elevations,
            startTime: completedRoute.startTime,
            time: completedRoute.time
        ) { result in
            let finish = {
                if case .success = result {
                    records.updateCyclingRecords(
                        speeds: completedRoute.speeds,
                        distance: completedRoute.distance,
                        startTime: completedRoute.startTime,
                        time: completedRoute.time
                    )
                    cleanupAfterSuccess()
                }
                alwaysCleanup()
                completion(result)
            }
            if Thread.isMainThread {
                finish()
            } else {
                DispatchQueue.main.async(execute: finish)
            }
        }
    }
}

extension PersistenceController: BikeRideStoring {}

extension CyclingRecords: CyclingRecordsUpdating {}
