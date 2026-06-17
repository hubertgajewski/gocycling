//
//  PersistedStoreSnapshot.swift
//  Go CyclingTests
//

import Foundation
import Testing

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

private let persistedStoreSnapshotGate = PersistedStoreSnapshotGate()

private final class PersistedStoreSnapshotGate: @unchecked Sendable {
  private let semaphore = DispatchSemaphore(value: 1)

  func acquire() {
    semaphore.wait()
  }

  func release() {
    semaphore.signal()
  }
}

private final class PersistedStoreSnapshotPermit: @unchecked Sendable {
  private let stateLock = NSLock()
  private var isReleased = false

  init() {
    persistedStoreSnapshotGate.acquire()
  }

  deinit {
    release()
  }

  func release() {
    stateLock.lock()
    let shouldRelease = !isReleased
    isReleased = true
    stateLock.unlock()

    if shouldRelease {
      persistedStoreSnapshotGate.release()
    }
  }
}

struct PersistedStoreSnapshot {
  private let permit: PersistedStoreSnapshotPermit
  private let keys: [String]
  private let userDefaultsValues: [String: Any]
  private let userDefaultsKeys: Set<String>
  private let iCloudValues: [String: Any]
  private let iCloudKeys: Set<String>

  init(keys: [String]) {
    self.permit = PersistedStoreSnapshotPermit()
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
    defer { permit.release() }

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

@Suite("PersistedStoreSnapshot", .serialized)
struct PersistedStoreSnapshotTests {
  @Test("serializes overlapping snapshots")
  func serializesOverlappingSnapshots() {
    let key = "GoCyclingTests.persistedStoreSnapshotLock"
    let userDefaultsValue = UserDefaults.standard.object(forKey: key)
    let iCloudValue = NSUbiquitousKeyValueStore.default.object(forKey: key)
    defer { restoreProbeValues(userDefaultsValue: userDefaultsValue, iCloudValue: iCloudValue) }

    let firstSnapshotReady = DispatchSemaphore(value: 0)
    let releaseFirstSnapshot = DispatchSemaphore(value: 0)
    let secondSnapshotAttemptStarted = DispatchSemaphore(value: 0)
    let secondSnapshotReturned = DispatchSemaphore(value: 0)
    let completedSnapshots = DispatchSemaphore(value: 0)
    defer { releaseFirstSnapshot.signal() }

    DispatchQueue.global(qos: .userInitiated).async {
      let firstSnapshot = PersistedStoreSnapshot(keys: [key])
      firstSnapshotReady.signal()
      releaseFirstSnapshot.wait()
      firstSnapshot.restore()
      completedSnapshots.signal()
    }

    #expect(firstSnapshotReady.wait(timeout: .now() + .seconds(2)) == .success)

    DispatchQueue.global(qos: .userInitiated).async {
      secondSnapshotAttemptStarted.signal()
      let secondSnapshot = PersistedStoreSnapshot(keys: [key])
      secondSnapshotReturned.signal()
      secondSnapshot.restore()
      completedSnapshots.signal()
    }

    #expect(secondSnapshotAttemptStarted.wait(timeout: .now() + .seconds(2)) == .success)
    let secondReturnedBeforeRelease = secondSnapshotReturned.wait(
      timeout: .now() + .milliseconds(200)
    )
    #expect(secondReturnedBeforeRelease == .timedOut)

    releaseFirstSnapshot.signal()
    if secondReturnedBeforeRelease == .timedOut {
      #expect(secondSnapshotReturned.wait(timeout: .now() + .seconds(2)) == .success)
    }
    #expect(completedSnapshots.wait(timeout: .now() + .seconds(2)) == .success)
    #expect(completedSnapshots.wait(timeout: .now() + .seconds(2)) == .success)
  }

  private func restoreProbeValues(userDefaultsValue: Any?, iCloudValue: Any?) {
    let key = "GoCyclingTests.persistedStoreSnapshotLock"
    restoreProbeValue(userDefaultsValue, key: key, in: UserDefaults.standard)
    restoreProbeValue(iCloudValue, key: key, in: NSUbiquitousKeyValueStore.default)
    NSUbiquitousKeyValueStore.default.synchronize()
  }

  private func restoreProbeValue(_ value: Any?, key: String, in defaults: UserDefaults) {
    if let value {
      defaults.set(value, forKey: key)
    } else {
      defaults.removeObject(forKey: key)
    }
  }

  private func restoreProbeValue(_ value: Any?, key: String, in store: NSUbiquitousKeyValueStore) {
    if let value {
      store.set(value, forKey: key)
    } else {
      store.removeObject(forKey: key)
    }
  }
}
