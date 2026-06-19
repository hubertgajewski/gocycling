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

    let fixture = SharedStoreRideFixture()
    defer { fixture.cleanup() }

    _ = fixture.insert(
      name: "Issue41-Commute",
      distance: 1_000,
      start: fixtureDate(2026, 6, 15),
      time: 300
    )
    _ = fixture.insert(
      name: "Issue41-Training",
      distance: 2_000,
      start: fixtureDate(2026, 6, 16),
      time: 600
    )
    try fixture.save()

    let viewModel = RouteNamingViewModel()
    let insertedRouteNames = viewModel.routeNames.filter { $0.hasPrefix("Issue41-") }

    #expect(viewModel.allBikeRides.contains { $0.cyclingRouteName == "Issue41-Commute" })
    #expect(viewModel.allBikeRides.contains { $0.cyclingRouteName == "Issue41-Training" })
    #expect(insertedRouteNames == ["Issue41-Commute", "Issue41-Training"])
  }
}
