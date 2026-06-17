//
//  RecordsFormattingTests.swift
//  Go CyclingTests
//

import Foundation
import Testing

@testable import Go_Cycling

@Suite("RecordsFormatting")
struct RecordsFormattingTests {

  @Test("formats optional dates")
  func formatsOptionalDates() throws {
    var components = DateComponents()
    components.calendar = Calendar(identifier: .gregorian)
    components.timeZone = TimeZone(secondsFromGMT: 0)
    components.year = 2026
    components.month = 6
    components.day = 17
    let date = try #require(components.date)

    #expect(RecordsFormatting.formatOptionalDate(date: nil) == nil)
    #expect(RecordsFormatting.formatOptionalDate(date: date) == "June 17, 2026")
  }

  @Test("uses expected record labels")
  func usesExpectedRecordLabels() {
    #expect(
      RecordsFormatting.recordsStrings == [
        "Total Distance Cycled",
        "Total Cycling Time",
        "Total Saved Cycling Routes",
        "Longest Distance Cycled",
        "Longest Cycling Time",
        "Best Average Cycling Speed",
      ]
    )
  }

  @Test("uses expected section headers")
  func usesExpectedSectionHeaders() {
    #expect(
      RecordsFormatting.headerStrings == [
        "Cycling Records",
        "Cycling Charts",
        "Activity Awards",
      ]
    )
  }

  @Test("uses expected section footers")
  func usesExpectedSectionFooters() {
    #expect(
      RecordsFormatting.footerStrings == [
        "Click on a row above to view a detailed chart of that activity period. Percentage changes compare the current activity period to the previous one. This data is based on the currently saved cycling routes.",
        "Progress toward unlocking exclusive alternate app icons. Unlocked icons will not be lost when routes are deleted or statistics are reset.",
      ]
    )
  }

  @Test("uses metric and imperial best-average-speed footer text")
  func usesCyclingRecordsFooterText() {
    #expect(
      RecordsFormatting.getCyclingRecordsFooterText(usingMetric: true)
        == "Only routes longer than 1 km are counted for the best average cycling speed record."
    )
    #expect(
      RecordsFormatting.getCyclingRecordsFooterText(usingMetric: false)
        == "Only routes longer than 0.62 mi are counted for the best average cycling speed record."
    )
  }
}
