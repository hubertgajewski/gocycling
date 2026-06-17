//
//  UITestingRouteSaveFixture.swift
//  Go Cycling
//

import CoreLocation
import Foundation

enum UITestingRouteSaveFixture {
    #if DEBUG
    private static var hasRun = false

    static func runIfNeeded(
        persistenceController: PersistenceController,
        records: CyclingRecords,
        preferences: Preferences
    ) {
        guard UITesting.shouldRunRouteSaveFixture && !hasRun else { return }
        hasRun = true

        preferences.updateStringPreference(preference: .selectedRoute, value: "")
        persistenceController.deleteAllBikeRides()
        CyclingRecords.resetStatistics()

        CompletedRouteSaveCoordinator(
            persistenceController: persistenceController,
            records: records
        ).save(Self.completedRoute)
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
    #else
    static func runIfNeeded(
        persistenceController: PersistenceController,
        records: CyclingRecords,
        preferences: Preferences
    ) {}
    #endif
}
