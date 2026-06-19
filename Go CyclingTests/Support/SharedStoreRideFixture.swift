//
//  SharedStoreRideFixture.swift
//  Go CyclingTests
//

import CoreData
import CoreLocation
import Foundation

@testable import Go_Cycling

@MainActor
final class SharedStoreRideFixture {
  private let context: NSManagedObjectContext
  private var insertedRides: [BikeRide] = []

  init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
    self.context = context
  }

  @discardableResult
  func insert(
    name: String,
    distance: Double,
    start: Date,
    time: Double,
    speeds: [CLLocationSpeed] = [5]
  ) -> BikeRide {
    let ride = BikeRide(context: context)
    ride.cyclingRouteName = name
    ride.cyclingDistance = distance
    ride.cyclingStartTime = start
    ride.cyclingTime = time
    ride.cyclingSpeeds = speeds
    ride.cyclingLatitudes = [51.5]
    ride.cyclingLongitudes = [-0.1]
    ride.cyclingElevations = [10]
    insertedRides.append(ride)
    return ride
  }

  func save() throws {
    try context.save()
  }

  func cleanup() {
    for ride in insertedRides {
      context.delete(ride)
    }
    insertedRides.removeAll()
    try? context.save()
  }
}

func fixtureDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
  var components = DateComponents()
  components.calendar = Calendar(identifier: .gregorian)
  components.timeZone = TimeZone(secondsFromGMT: 0)
  components.year = year
  components.month = month
  components.day = day
  return components.date!
}
