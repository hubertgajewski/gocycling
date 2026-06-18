//
//  PersistedStoreSnapshot.swift
//  Go CyclingTests
//

import Foundation

// Process-wide: UserDefaults and NSUbiquitousKeyValueStore are shared singletons.
private let persistedStoreSnapshotLock = NSRecursiveLock()

/// Serializes snapshot lifetimes across the test target. Swift Testing runs suites
/// in parallel; without this, one test could mutate shared defaults while another
/// is between `init` and `restore()`, causing flaky restores.
private final class PersistedStoreSnapshotLockToken {
  private var isUnlocked = false

  init() {
    persistedStoreSnapshotLock.lock()
  }

  deinit {
    unlockIfNeeded()
  }

  func unlockIfNeeded() {
    guard !isUnlocked else { return }
    isUnlocked = true
    persistedStoreSnapshotLock.unlock()
  }
}

let iCloudSyncPreferenceKey = "iCloudOn"

let cyclingRecordStoreKeys = [
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

struct PersistedStoreSnapshot {
  private let lockToken = PersistedStoreSnapshotLockToken()
  private let keys: [String]
  private let userDefaultsValues: [String: Any]
  private let userDefaultsKeys: Set<String>
  private let iCloudValues: [String: Any]
  private let iCloudKeys: Set<String>

  init(keys: [String]) {
    self.keys = keys

    var userDefaultsValues = [String: Any]()
    var userDefaultsKeys = Set<String>()
    var iCloudValues = [String: Any]()
    var iCloudKeys = Set<String>()

    for key in keys {
      if let value = UserDefaults.standard.object(forKey: key), !(value is NSNull) {
        userDefaultsKeys.insert(key)
        userDefaultsValues[key] = value
      }
      if let value = NSUbiquitousKeyValueStore.default.object(forKey: key), !(value is NSNull) {
        iCloudKeys.insert(key)
        iCloudValues[key] = value
      }
    }

    self.userDefaultsValues = userDefaultsValues
    self.userDefaultsKeys = userDefaultsKeys
    self.iCloudValues = iCloudValues
    self.iCloudKeys = iCloudKeys
  }

  func restore() {
    defer { lockToken.unlockIfNeeded() }

    for key in keys {
      restore(
        key: key,
        hadKey: userDefaultsKeys.contains(key),
        value: userDefaultsValues[key],
        in: UserDefaults.standard
      )
      restore(
        key: key,
        hadKey: iCloudKeys.contains(key),
        value: iCloudValues[key],
        in: NSUbiquitousKeyValueStore.default
      )
    }
    NSUbiquitousKeyValueStore.default.synchronize()
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

func ubiquitousStorePersistsValues() -> Bool {
  let key = "GoCyclingTests.ubiquitousStoreProbe"
  let store = NSUbiquitousKeyValueStore.default
  let existingValue = store.object(forKey: key)
  store.set("available", forKey: key)
  store.synchronize()
  let persistsValues = store.string(forKey: key) == "available"
  if let existingValue {
    store.set(existingValue, forKey: key)
  } else {
    store.removeObject(forKey: key)
  }
  store.synchronize()
  return persistsValues
}
