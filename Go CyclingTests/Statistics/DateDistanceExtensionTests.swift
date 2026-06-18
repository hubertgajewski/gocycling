//
//  DateDistanceExtensionTests.swift
//  Go CyclingTests
//

import Foundation
import Testing

@testable import Go_Cycling

@Suite("Date distance extension")
struct DateDistanceExtensionTests {

  @Test("returns day distance relative to the chart reference date")
  func returnsDayDistanceRelativeToChartReferenceDate() {
    let calendar = chartCalendar()
    let startOfToday = calendar.startOfDay(for: Date())
    let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
    let yesterday = daysFromToday(-1, calendar: calendar)
    let today = daysFromToday(0, calendar: calendar)

    #expect(yesterday.fullDistance(from: endOfToday, resultIn: .day, calendar: calendar) == 1)
    #expect(today.fullDistance(from: endOfToday, resultIn: .day, calendar: calendar) == 0)
    let sixDaysAgoDistance = daysFromToday(-6, calendar: calendar).fullDistance(
      from: endOfToday,
      resultIn: .day,
      calendar: calendar
    )
    #expect(sixDaysAgoDistance == 6)
  }
}
