//
//  StatisticsChartFixtures.swift
//  Go CyclingTests
//

import CoreData
import Foundation

@testable import Go_Cycling

let chartViewModelStoreKeys = [
  iCloudSyncPreferenceKey,
  ReviewManager.reviewCountKey,
  ReviewManager.completedRouteKey,
  ReviewManager.reviewRequestVersionKey,
]

func chartCalendar() -> Calendar {
  var calendar = Calendar.current
  calendar.timeZone = NSTimeZone.local
  return calendar
}

func daysFromToday(_ offset: Int, calendar: Calendar = chartCalendar()) -> Date {
  let today = calendar.startOfDay(for: Date())
  let day = calendar.date(byAdding: .day, value: offset, to: today)!
  return calendar.date(byAdding: .hour, value: 12, to: day)!
}

func makeInMemoryChartPersistence() -> PersistenceController {
  UserDefaults.standard.set(false, forKey: iCloudSyncPreferenceKey)
  return PersistenceController(inMemory: true)
}

@discardableResult
func makeChartRide(
  in context: NSManagedObjectContext,
  distance: Double,
  time: Double,
  start: Date,
  name: String = "Test"
) -> BikeRide {
  let entity = NSEntityDescription.entity(forEntityName: "BikeRide", in: context)!
  let ride = BikeRide(entity: entity, insertInto: context)
  ride.cyclingRouteName = name
  ride.cyclingDistance = distance
  ride.cyclingTime = time
  ride.cyclingStartTime = start
  ride.cyclingSpeeds = []
  ride.cyclingLatitudes = []
  ride.cyclingLongitudes = []
  ride.cyclingElevations = []
  return ride
}

func formattedChartDateRange(
  from start: Date,
  to end: Date,
  calendar: Calendar = chartCalendar()
) -> String {
  let formatter = DateFormatter()
  formatter.calendar = calendar
  formatter.timeZone = calendar.timeZone
  formatter.dateFormat = "MMMM dd, yyyy"
  return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
}

func formattedChartDate(_ date: Date, calendar: Calendar = chartCalendar()) -> String {
  let formatter = DateFormatter()
  formatter.calendar = calendar
  formatter.timeZone = calendar.timeZone
  formatter.dateFormat = "MMMM dd, yyyy"
  return formatter.string(from: date)
}
