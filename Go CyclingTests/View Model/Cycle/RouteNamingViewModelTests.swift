//
//  RouteNamingViewModelTests.swift
//  Go CyclingTests
//

import CoreData
import Foundation
import Testing

@testable import Go_Cycling

@Suite("RouteNamingViewModel", .serialized)
@MainActor
struct RouteNamingViewModelTests {

  @Test("reflects current route names from stored bike rides")
  func reflectsCurrentRouteNamesFromStoredBikeRides() async throws {
    let snapshot = await PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let persistence = PersistenceController.shared
    defer { persistence.deleteAllBikeRides() }
    persistence.deleteAllBikeRides()

    let context = persistence.container.viewContext
    _ = makeNamingRide(in: context, name: "Commute")
    _ = makeNamingRide(in: context, name: "Training")
    try context.save()

    let viewModel = RouteNamingViewModel()

    #expect(viewModel.allBikeRides.count == 2)
    #expect(viewModel.routeNames == ["Commute", "Training"])
  }
}

private func makeNamingRide(in context: NSManagedObjectContext, name: String) -> BikeRide {
  let ride = BikeRide(context: context)
  ride.cyclingRouteName = name
  ride.cyclingDistance = 1_000
  ride.cyclingStartTime = Date(timeIntervalSince1970: 1_000)
  ride.cyclingTime = 300
  ride.cyclingSpeeds = [5]
  ride.cyclingLatitudes = [51.5]
  ride.cyclingLongitudes = [-0.1]
  ride.cyclingElevations = [10]
  return ride
}
