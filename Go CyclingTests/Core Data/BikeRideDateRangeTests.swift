//
//  BikeRideDateRangeTests.swift
//  Go CyclingTests
//

import CoreData
import Foundation
import Testing

@testable import Go_Cycling

@Suite("Bike ride date-range fetch requests", .serialized)
@MainActor
struct BikeRideDateRangeTests {

  @Test("returns non-nil requests for all six statistics windows")
  func returnsNonNilRequestsForAllWindows() {
    let requests = BikeRide.fetchRequestsWithDateRanges()

    #expect(requests.count == 6)
    #expect(requests.allSatisfy { $0 != nil })
  }

  @Test("fetches rides only inside each statistics window")
  func fetchesRidesOnlyInsideEachStatisticsWindow() async throws {
    let snapshot = await PersistedStoreSnapshot(keys: [iCloudSyncPreferenceKey])
    defer { snapshot.restore() }

    let persistence = makeInMemoryChartPersistence()
    let context = persistence.container.viewContext
    _ = [
      makeChartRide(
        in: context, distance: 100, time: 60, start: daysFromToday(-1), name: "week"),
      makeChartRide(
        in: context, distance: 200, time: 120, start: daysFromToday(-10), name: "prior-week"),
      makeChartRide(
        in: context, distance: 300, time: 180, start: daysFromToday(-20), name: "five-weeks"),
      makeChartRide(
        in: context, distance: 400, time: 240, start: daysFromToday(-50), name: "prior-five-weeks"),
      makeChartRide(
        in: context, distance: 500, time: 300, start: daysFromToday(-100), name: "thirty-weeks"),
      makeChartRide(
        in: context,
        distance: 600,
        time: 360,
        start: daysFromToday(-300),
        name: "prior-thirty-weeks"
      ),
      makeChartRide(
        in: context, distance: 700, time: 420, start: daysFromToday(-500), name: "outside"),
    ]
    try context.save()

    let requests = BikeRide.fetchRequestsWithDateRanges()
    let fetchedNames = try requests.map { request -> [String] in
      let rides = try context.fetch(try #require(request))
      return rides.map(\.cyclingRouteName).sorted()
    }

    #expect(fetchedNames[0] == ["week"])
    #expect(fetchedNames[1] == ["prior-week"])
    #expect(fetchedNames[2] == ["five-weeks", "prior-week", "week"])
    #expect(fetchedNames[3] == ["prior-five-weeks"])
    #expect(
      fetchedNames[4] == [
        "five-weeks",
        "prior-five-weeks",
        "prior-week",
        "thirty-weeks",
        "week",
      ]
    )
    #expect(fetchedNames[5] == ["prior-thirty-weeks"])
    #expect(fetchedNames.flatMap { $0 }.contains("outside") == false)
  }
}
