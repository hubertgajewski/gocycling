//
//  CycleViewTests.swift
//  Go CyclingTests
//

import Foundation
import Testing

@testable import Go_Cycling

@Suite("CycleView")
@MainActor
struct CycleViewTests {

  @Test("formats elapsed time as zero-padded hours minutes and seconds")
  func formatsElapsedTimeAsZeroPaddedHoursMinutesAndSeconds() {
    #expect(CycleView.formatTimeString(accumulatedTime: 0) == "00:00:00")
    #expect(CycleView.formatTimeString(accumulatedTime: 65) == "00:01:05")
    #expect(CycleView.formatTimeString(accumulatedTime: 3_661) == "01:01:01")
    #expect(CycleView.formatTimeString(accumulatedTime: 90_305) == "25:05:05")
  }
}
