//
//  CycleElapsedTimeFormattingTests.swift
//  Go CyclingTests
//

import Foundation
import Testing

@testable import Go_Cycling

@Suite("CycleElapsedTimeFormatting")
struct CycleElapsedTimeFormattingTests {

  @Test("formats elapsed time as zero-padded hours minutes and seconds")
  func formatsElapsedTimeAsZeroPaddedHoursMinutesAndSeconds() {
    #expect(CycleElapsedTimeFormatting.formatTimeString(accumulatedTime: 0) == "00:00:00")
    #expect(CycleElapsedTimeFormatting.formatTimeString(accumulatedTime: 65) == "00:01:05")
    #expect(CycleElapsedTimeFormatting.formatTimeString(accumulatedTime: 3_661) == "01:01:01")
    #expect(CycleElapsedTimeFormatting.formatTimeString(accumulatedTime: 90_305) == "25:05:05")
  }
}
