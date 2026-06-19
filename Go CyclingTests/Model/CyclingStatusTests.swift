//
//  CyclingStatusTests.swift
//  Go CyclingTests
//

import Foundation
import Testing

@testable import Go_Cycling

@Suite("CyclingStatus")
@MainActor
struct CyclingStatusTests {

  @Test("tracks cycling session state")
  func tracksCyclingSessionState() {
    let status = CyclingStatus()
    #expect(status.isCycling == false)

    status.startedCycling()
    #expect(status.isCycling == true)

    status.stoppedCycling()
    #expect(status.isCycling == false)
  }
}
