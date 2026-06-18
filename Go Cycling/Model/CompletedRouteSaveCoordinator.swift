//
//  CompletedRouteSaveCoordinator.swift
//  Go Cycling
//

import CoreLocation
import Foundation

// Ending a ride stops live location side effects before Core Data finishes, so
// the save path needs an immutable copy that cleanup cannot mutate underneath it.
struct CompletedRouteSnapshot {
    let locations: [CLLocation?]
    let speeds: [CLLocationSpeed?]
    let distance: Double
    let elevations: [CLLocationDistance?]
    let startTime: Date
    let time: Double
}

protocol BikeRideStoring {
    /// This boundary lets tests force save failures and verify records/cleanup
    /// stay blocked until a BikeRide is actually saved.
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

// The old stop path updated records and cleared samples even after save failure;
// this pipeline makes every success-only side effect wait for the saved BikeRide.
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
                    // Records and UI cleanup happen only after persistence succeeds;
                    // otherwise a failed save would still count or discard a ride.
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
