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

  private var savedUserDefaultsValues = [String: Any]()
  private var savedUserDefaultsKeys = Set<String>()
  private var savedICloudValues = [String: Any]()
  private var savedICloudKeys = Set<String>()
  private let persistedStoreKeys = [
    "didSetupRecords",
    "totalCyclingTime",
    "totalCyclingDistance",
    "unlockedIcons",
    "longestCyclingDistance",
    "longestCyclingTime",
    "fastestAverageSpeed",
    "fastestAverageSpeedDate",
    "longestCyclingDistanceDate",
    "longestCyclingTimeDate",
    "totalCyclingRoutes",
  ]

  override func setUpWithError() throws {
    continueAfterFailure = false

    savedUserDefaultsValues = [:]
    savedUserDefaultsKeys = []
    savedICloudValues = [:]
    savedICloudKeys = []

    for key in persistedStoreKeys {
      if let value = UserDefaults.standard.object(forKey: key), !(value is NSNull) {
        savedUserDefaultsKeys.insert(key)
        savedUserDefaultsValues[key] = value
      }
      if let value = NSUbiquitousKeyValueStore.default.object(forKey: key), !(value is NSNull) {
        savedICloudKeys.insert(key)
        savedICloudValues[key] = value
      }
    }
  }

  override func tearDownWithError() throws {
    for key in persistedStoreKeys {
      restore(
        key: key, hadKey: savedUserDefaultsKeys.contains(key), value: savedUserDefaultsValues[key],
        in: UserDefaults.standard)
      restore(
        key: key, hadKey: savedICloudKeys.contains(key), value: savedICloudValues[key],
        in: NSUbiquitousKeyValueStore.default)
    }
    NSUbiquitousKeyValueStore.default.synchronize()
  }

  func testResetStatisticsZerosTotalCyclingRoutesInLocalAndICloudStores() throws {
    UserDefaults.standard.set([Bool](repeating: false, count: 6), forKey: "unlockedIcons")
    NSUbiquitousKeyValueStore.default.set(
      [Bool](repeating: false, count: 6), forKey: "unlockedIcons")
    UserDefaults.standard.set(7, forKey: "totalCyclingRoutes")
    NSUbiquitousKeyValueStore.default.set(7 as Int, forKey: "totalCyclingRoutes")

    CyclingRecords.resetStatistics()

    XCTAssertEqual(UserDefaults.standard.integer(forKey: "totalCyclingRoutes"), 0)
    XCTAssertEqual(NSUbiquitousKeyValueStore.default.longLong(forKey: "totalCyclingRoutes"), 0)
  }

  private func restore(key: String, hadKey: Bool, value: Any?, in defaults: UserDefaults) {
    if hadKey, let value {
      defaults.set(value, forKey: key)
    } else {
      defaults.removeObject(forKey: key)
    }
  }

  private func restore(key: String, hadKey: Bool, value: Any?, in store: NSUbiquitousKeyValueStore)
  {
    if hadKey, let value {
      store.set(value, forKey: key)
    } else {
      store.removeObject(forKey: key)
    }
  }

}
