//
//  CyclingChartsViewModelTests.swift
//  Go CyclingTests
//

import Foundation
import Testing

@testable import Go_Cycling

@Suite("CyclingChartsViewModel", .serialized)
@MainActor
struct CyclingChartsViewModelTests {

  @Test("buckets past-week ride data and normalizes values")
  func bucketsPastWeekData() async {
    let snapshot = await PersistedStoreSnapshot(keys: chartViewModelStoreKeys)
    defer { snapshot.restore() }

    let persistence = makeInMemoryChartPersistence()
    let recentRide = makeChartRide(
      in: persistence.container.viewContext,
      distance: 1_000,
      time: 600,
      start: daysFromToday(-1)
    )
    let viewModel = CyclingChartsViewModel()
    viewModel.pastWeekData = [recentRide]
    viewModel.setPastWeekFormattedData()

    #expect(viewModel.pastData[0][5] == 1_000)
    #expect(viewModel.pastData[3][5] == 600)
    #expect(viewModel.pastData[6][5] == 1)
    #expect(viewModel.pastDataNormalized[0][5] == 1.0)
    #expect(viewModel.pastDataNormalized[3][5] == 1.0)
    #expect(viewModel.pastDataNormalized[6][5] == 1.0)
  }

  @Test("normalizes past-week buckets against the maximum value")
  func normalizesPastWeekBucketsAgainstMaximumValue() async {
    let snapshot = await PersistedStoreSnapshot(keys: chartViewModelStoreKeys)
    defer { snapshot.restore() }

    let persistence = makeInMemoryChartPersistence()
    let context = persistence.container.viewContext
    let yesterday = makeChartRide(
      in: context,
      distance: 1_000,
      time: 600,
      start: daysFromToday(-1)
    )
    let today = makeChartRide(
      in: context,
      distance: 2_000,
      time: 1_200,
      start: daysFromToday(0)
    )
    let viewModel = CyclingChartsViewModel()
    viewModel.pastWeekData = [yesterday, today]
    viewModel.setPastWeekFormattedData()

    #expect(viewModel.pastData[0] == [0, 0, 0, 0, 0, 1_000, 2_000])
    #expect(viewModel.pastDataNormalized[0] == [0, 0, 0, 0, 0, 0.5, 1.0])
    #expect(viewModel.pastDataNormalized[3] == [0, 0, 0, 0, 0, 0.5, 1.0])
    #expect(viewModel.pastDataNormalized[6] == [0, 0, 0, 0, 0, 1.0, 1.0])
  }

  @Test("ignores rides outside the past-week window")
  func ignoresRidesOutsidePastWeekWindow() async {
    let snapshot = await PersistedStoreSnapshot(keys: chartViewModelStoreKeys)
    defer { snapshot.restore() }

    let persistence = makeInMemoryChartPersistence()
    let outOfRange = makeChartRide(
      in: persistence.container.viewContext,
      distance: 1_000,
      time: 600,
      start: daysFromToday(-10)
    )
    let viewModel = CyclingChartsViewModel()
    viewModel.pastWeekData = [outOfRange]
    viewModel.setPastWeekFormattedData()

    #expect(viewModel.pastData[0].allSatisfy { $0 == 0 })
    #expect(viewModel.pastDataNormalized[0].allSatisfy { $0 == 0 })
  }

  @Test("buckets past-five-week ride data into weekly buckets")
  func bucketsPastFiveWeekRideData() async {
    let snapshot = await PersistedStoreSnapshot(keys: chartViewModelStoreKeys)
    defer { snapshot.restore() }

    let persistence = makeInMemoryChartPersistence()
    let context = persistence.container.viewContext
    let thisWeek = makeChartRide(
      in: context,
      distance: 100,
      time: 60,
      start: daysFromToday(-1)
    )
    let priorWeek = makeChartRide(
      in: context,
      distance: 200,
      time: 120,
      start: daysFromToday(-10)
    )
    let outOfRange = makeChartRide(
      in: context,
      distance: 900,
      time: 540,
      start: daysFromToday(-40)
    )
    let viewModel = CyclingChartsViewModel()
    viewModel.past5WeeksData = [thisWeek, priorWeek, outOfRange]
    viewModel.setPast5WeeksFormattedData()

    #expect(viewModel.pastData[1] == [0, 0, 0, 200, 100])
    #expect(viewModel.pastData[4] == [0, 0, 0, 120, 60])
    #expect(viewModel.pastData[7] == [0, 0, 0, 1, 1])
    #expect(viewModel.pastDataNormalized[1] == [0, 0, 0, 1.0, 0.5])
    #expect(viewModel.pastDataNormalized[4] == [0, 0, 0, 1.0, 0.5])
    #expect(viewModel.pastDataNormalized[7] == [0, 0, 0, 1.0, 1.0])
  }

  @Test("buckets past-thirty-week ride data into five-week buckets")
  func bucketsPastThirtyWeekRideData() async {
    let snapshot = await PersistedStoreSnapshot(keys: chartViewModelStoreKeys)
    defer { snapshot.restore() }

    let persistence = makeInMemoryChartPersistence()
    let context = persistence.container.viewContext
    let recent = makeChartRide(
      in: context,
      distance: 100,
      time: 60,
      start: daysFromToday(-10)
    )
    let middle = makeChartRide(
      in: context,
      distance: 300,
      time: 180,
      start: daysFromToday(-50)
    )
    let outOfRange = makeChartRide(
      in: context,
      distance: 900,
      time: 540,
      start: daysFromToday(-250)
    )
    let viewModel = CyclingChartsViewModel()
    viewModel.past30WeeksData = [recent, middle, outOfRange]
    viewModel.setPast30WeeksFormattedData()

    #expect(viewModel.pastData[2] == [0, 0, 0, 0, 300, 100])
    #expect(viewModel.pastData[5] == [0, 0, 0, 0, 180, 60])
    #expect(viewModel.pastData[8] == [0, 0, 0, 0, 1, 1])
    #expect(viewModel.pastDataNormalized[2] == [0, 0, 0, 0, 1.0, 1.0 / 3.0])
    #expect(viewModel.pastDataNormalized[5] == [0, 0, 0, 0, 1.0, 1.0 / 3.0])
    #expect(viewModel.pastDataNormalized[8] == [0, 0, 0, 0, 1.0, 1.0])
  }

  @Test("leaves chart arrays zeroed when ride data is empty")
  func leavesChartArraysZeroedWhenRideDataIsEmpty() async {
    let snapshot = await PersistedStoreSnapshot(keys: chartViewModelStoreKeys)
    defer { snapshot.restore() }

    let viewModel = CyclingChartsViewModel()
    viewModel.pastWeekData = []
    viewModel.past5WeeksData = []
    viewModel.past30WeeksData = []
    viewModel.setPastWeekFormattedData()
    viewModel.setPast5WeeksFormattedData()
    viewModel.setPast30WeeksFormattedData()

    for index in [0, 1, 2, 3, 4, 5, 6, 7, 8] {
      #expect(viewModel.pastData[index].allSatisfy { $0 == 0 })
      #expect(viewModel.pastDataNormalized[index].allSatisfy { $0 == 0 })
    }
  }

  @Test("formats chart date ranges for each statistics window")
  func formatsChartDateRanges() async {
    let snapshot = await PersistedStoreSnapshot(keys: chartViewModelStoreKeys)
    defer { snapshot.restore() }

    let calendar = chartCalendar()
    let startOfToday = calendar.startOfDay(for: Date())
    let viewModel = CyclingChartsViewModel()

    let weekRange = formattedChartDateRange(
      from: calendar.date(byAdding: .day, value: -6, to: startOfToday)!,
      to: startOfToday,
      calendar: calendar
    )
    let fiveWeekRange = formattedChartDateRange(
      from: calendar.date(byAdding: .day, value: -34, to: startOfToday)!,
      to: startOfToday,
      calendar: calendar
    )
    let thirtyWeekRange = formattedChartDateRange(
      from: calendar.date(byAdding: .day, value: -181, to: startOfToday)!,
      to: startOfToday,
      calendar: calendar
    )

    #expect(viewModel.getDateRange(index: 0) == weekRange)
    #expect(viewModel.getDateRange(index: 1) == fiveWeekRange)
    #expect(viewModel.getDateRange(index: 2) == thirtyWeekRange)
    #expect(viewModel.getDateRange(index: 99) == thirtyWeekRange)
  }

  @Test("formats individual chart bar date ranges")
  func formatsIndividualChartBarDateRanges() async {
    let snapshot = await PersistedStoreSnapshot(keys: chartViewModelStoreKeys)
    defer { snapshot.restore() }

    let calendar = chartCalendar()
    let startOfToday = calendar.startOfDay(for: Date())
    let viewModel = CyclingChartsViewModel()

    let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
    let yesterdayLabel = formattedChartDate(yesterday, calendar: calendar)
    #expect(viewModel.getIndividualDateRange(index: 0, entryIndex: 5) == yesterdayLabel)

    let weekEnd = calendar.date(byAdding: .day, value: -7, to: startOfToday)!
    let weekStart = calendar.date(byAdding: .day, value: -13, to: startOfToday)!
    let weekLabel = formattedChartDateRange(from: weekStart, to: weekEnd, calendar: calendar)
    #expect(viewModel.getIndividualDateRange(index: 1, entryIndex: 3) == weekLabel)

    let blockEnd = calendar.date(byAdding: .day, value: -35, to: startOfToday)!
    let blockStart = calendar.date(byAdding: .day, value: -69, to: startOfToday)!
    let blockLabel = formattedChartDateRange(from: blockStart, to: blockEnd, calendar: calendar)
    #expect(viewModel.getIndividualDateRange(index: 2, entryIndex: 4) == blockLabel)
  }
}
