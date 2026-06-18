//
//  SingleChartListCellViewTests.swift
//  Go CyclingTests
//

import Testing

@testable import Go_Cycling

@Suite("SingleChartListCellView percentages")
struct SingleChartListCellViewTests {

  @Test("formats zero, increase, decrease, and previous-zero percentage changes")
  func formatsPercentageChanges() {
    let unchanged = makeCell(distances: [100, 100], times: [60, 60], routes: [2, 2])
    #expect(unchanged.getPercentageChange(index: 0) == 0)
    #expect(unchanged.getPercentageString(index: 0) == "0%")

    let increase = makeCell(distances: [100, 150], times: [60, 90], routes: [2, 4])
    #expect(increase.getPercentageChange(index: 0) == 50)
    #expect(increase.getPercentageString(index: 0) == "↑50%")
    #expect(increase.getPercentageChange(index: 1) == 50)
    #expect(increase.getPercentageString(index: 1) == "↑50%")
    #expect(increase.getPercentageChange(index: 2) == 100)
    #expect(increase.getPercentageString(index: 2) == "↑100%")

    let decrease = makeCell(distances: [200, 100], times: [120, 60], routes: [4, 2])
    #expect(decrease.getPercentageChange(index: 0) == -50)
    #expect(decrease.getPercentageString(index: 0) == "↓50%")

    let previousZero = makeCell(distances: [0, 100], times: [0, 60], routes: [0, 2])
    #expect(previousZero.getPercentageChange(index: 0) == 100)
    #expect(previousZero.getPercentageString(index: 0) == "↑100%")
    #expect(previousZero.getPercentageChange(index: 1) == 100)
    #expect(previousZero.getPercentageString(index: 1) == "↑100%")
    #expect(previousZero.getPercentageChange(index: 2) == 100)
    #expect(previousZero.getPercentageString(index: 2) == "↑100%")
  }

  @Test("uses integer division for route-count percentage changes")
  func usesIntegerDivisionForRouteCountPercentageChanges() {
    let cell = makeCell(distances: [100, 150], times: [60, 90], routes: [2, 3])

    #expect(cell.getPercentageChange(index: 2) == 0)
    #expect(cell.getPercentageString(index: 2) == "0%")
  }

  @Test("caps displayed percentages above 999")
  func capsDisplayedPercentagesAbove999() {
    let cell = makeCell(distances: [1, 2_000], times: [1, 2_000], routes: [1, 2_000])

    #expect(cell.getPercentageChange(index: 0) == 199_900)
    #expect(cell.getPercentageString(index: 0) == "↑>999%")
    #expect(cell.getPercentageString(index: 1) == "↑>999%")
    #expect(cell.getPercentageString(index: 2) == "↑>999%")
  }

  @Test("returns zero for unknown metric indexes")
  func returnsZeroForUnknownMetricIndexes() {
    let cell = makeCell(distances: [100, 200], times: [60, 120], routes: [1, 2])

    #expect(cell.getPercentageChange(index: 3) == 0)
    #expect(cell.getPercentageString(index: 3) == "0%")
  }
}

private func makeCell(
  distances: [Double],
  times: [Double],
  routes: [Int]
) -> SingleChartListCellView {
  SingleChartListCellView(
    distances: distances,
    times: times,
    numberOfRoutes: routes,
    index: 0
  )
}
