//
//  UITestingRouteSaveFixture.swift
//  Go Cycling
//

import CoreLocation
import Foundation

#if DEBUG
enum UITestingRouteSaveFixtureError: Error, Equatable {
    case nonIsolatedStore
}
#endif

enum UITestingRouteSaveFixture {
    #if DEBUG
    private static var hasRun = false

    static func runIfNeeded(
        persistenceController: PersistenceController,
        records: CyclingRecordsUpdating? = nil,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        // One seeded ride exercises History route-save UI while avoiding
        // GPS/timer nondeterminism that makes smoke tests flaky.
        guard UITesting.shouldSeedRouteSaveFixture(arguments: arguments) && !hasRun else { return }
        // The fixture deletes all rides before seeding; verify isolation first so
        // a misconfigured UI-test launch cannot erase the user's saved routes.
        guard persistenceController.isUsingPersistentStore(at: UITesting.isolatedPersistenceStoreURL) else {
            completion(.failure(UITestingRouteSaveFixtureError.nonIsolatedStore))
            return
        }
        hasRun = true

        persistenceController.deleteAllBikeRides()
        let recordsUpdater = records ?? FixtureCyclingRecordsUpdater()

        CompletedRouteSaveCoordinator(
            persistenceController: persistenceController,
            records: recordsUpdater
        ).save(Self.completedRoute, completion: { result in
            completion(result.map { _ in () })
        })
    }

    static func resetForTesting() {
        hasRun = false
    }

    private static let completedRoute = CompletedRouteSnapshot(
        locations: [
            CLLocation(latitude: 51.5, longitude: -0.12),
            CLLocation(latitude: 52.0, longitude: -0.2),
        ],
        speeds: [4.2, 5.5],
        distance: 1_500,
        elevations: [15, 21],
        startTime: Date(timeIntervalSince1970: 1_800),
        time: 300
    )

    private final class FixtureCyclingRecordsUpdater: CyclingRecordsUpdating {
        // The fixture only needs a saved BikeRide; updating statistics here would
        // make History setup depend on record side effects that this smoke does not test.
        func updateCyclingRecords(
            speeds: [CLLocationSpeed?],
            distance: Double,
            startTime: Date,
            time: Double
        ) {}
    }
    #else
    static func runIfNeeded(
        persistenceController: PersistenceController,
        records: CyclingRecordsUpdating? = nil,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {}
    #endif
}
