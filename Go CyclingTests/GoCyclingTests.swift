//
//  GoCyclingTests.swift
//  Go CyclingTests
//
//  Created by Anthony Hopkins on 2021-03-14.
//

import XCTest
@testable import Go_Cycling

// CI scaffolding: minimal unit coverage until a follow-up issue refactors tests
// (Swift Testing, shared fixtures, and broader model coverage).
class GoCyclingTests: XCTestCase {

    private let totalCyclingRoutesKey = "totalCyclingRoutes"

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: totalCyclingRoutesKey)
        NSUbiquitousKeyValueStore.default.removeObject(forKey: totalCyclingRoutesKey)
    }

    func testResetStatisticsZerosTotalCyclingRoutesInLocalAndICloudStores() throws {
        UserDefaults.standard.set(7, forKey: totalCyclingRoutesKey)
        NSUbiquitousKeyValueStore.default.set(7 as Int, forKey: totalCyclingRoutesKey)

        CyclingRecords.resetStatistics()

        XCTAssertEqual(UserDefaults.standard.integer(forKey: totalCyclingRoutesKey), 0)
        XCTAssertEqual(NSUbiquitousKeyValueStore.default.longLong(forKey: totalCyclingRoutesKey), 0)
    }
}
