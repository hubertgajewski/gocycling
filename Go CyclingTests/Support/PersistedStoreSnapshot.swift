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
  private let lock = NSLock()
  private var isAvailable = true
  private var waiters = [CheckedContinuation<Void, Never>]()

  func acquirePermit() async -> PersistedStoreSnapshotPermit {
    await acquire()
    return PersistedStoreSnapshotPermit(gate: self)
  }

  private func acquire() async {
    await withCheckedContinuation { continuation in
      lock.lock()
      if isAvailable {
        isAvailable = false
        lock.unlock()
        continuation.resume()
      } else {
        waiters.append(continuation)
        lock.unlock()
      }
    }
  }

  func release() {
    let waiter: CheckedContinuation<Void, Never>?

    lock.lock()
    if waiters.isEmpty {
      isAvailable = true
      waiter = nil
    } else {
      waiter = waiters.removeFirst()
    }
    lock.unlock()

    waiter?.resume()
  }
}

private final class PersistedStoreSnapshotPermit: @unchecked Sendable {
  private let gate: PersistedStoreSnapshotGate
  private let stateLock = NSLock()
  private var isReleased = false

  init(gate: PersistedStoreSnapshotGate) {
    self.gate = gate
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
      gate.release()
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

  init(keys: [String]) async {
    self.permit = await persistedStoreSnapshotGate.acquirePermit()
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
  @Test("waiting for a permit leaves the main actor runnable")
  @MainActor
  func waitingForPermitLeavesMainActorRunnable() async throws {
    let gate = PersistedStoreSnapshotGate()
    let firstPermit = await gate.acquirePermit()
    let probe = PersistedStoreSnapshotGateProbe()
    let mainActorProbeRecorded = DispatchSemaphore(value: 0)

    let waitingTask = Task { @MainActor in
      probe.recordAttempt()
      let secondPermit = await gate.acquirePermit()
      probe.recordAcquire()
      secondPermit.release()
    }

    DispatchQueue.global(qos: .userInitiated).async {
      if probe.waitForAttempt(timeout: .now() + .seconds(2)) {
        DispatchQueue.main.async {
          probe.recordMainActorProbe()
          mainActorProbeRecorded.signal()
        }
      }

      let probeResult = mainActorProbeRecorded.wait(timeout: .now() + .seconds(2))
      probe.recordProbeCompletedBeforeRelease(probeResult == .success)
      probe.recordRelease()
      firstPermit.release()
    }

    await waitingTask.value
    let times = probe.snapshot()
    let mainActorProbeAt = try #require(times.mainActorProbeAt)
    let releaseAt = try #require(times.releaseAt)
    #expect(times.probeCompletedBeforeRelease == true)
    #expect(mainActorProbeAt < releaseAt)
  }

  @Test("serializes overlapping permits")
  func serializesOverlappingPermits() async {
    let gate = PersistedStoreSnapshotGate()
    let firstPermit = await gate.acquirePermit()
    defer { firstPermit.release() }

    let secondPermitAttemptStarted = DispatchSemaphore(value: 0)
    let secondPermitAcquired = DispatchSemaphore(value: 0)
    let secondPermitReleased = DispatchSemaphore(value: 0)

    Task.detached(priority: .userInitiated) {
      secondPermitAttemptStarted.signal()
      let secondPermit = await gate.acquirePermit()
      secondPermitAcquired.signal()
      secondPermit.release()
      secondPermitReleased.signal()
    }

    #expect(
      await waitForSemaphore(secondPermitAttemptStarted, timeout: .now() + .seconds(2))
        == .success)
    let secondAcquiredBeforeRelease = await waitForSemaphore(
      secondPermitAcquired,
      timeout: .now() + .milliseconds(200)
    )
    #expect(secondAcquiredBeforeRelease == .timedOut)

    firstPermit.release()
    if secondAcquiredBeforeRelease == .timedOut {
      #expect(
        await waitForSemaphore(secondPermitAcquired, timeout: .now() + .seconds(2))
          == .success
      )
    }
    #expect(
      await waitForSemaphore(secondPermitReleased, timeout: .now() + .seconds(2))
        == .success
    )
  }
}

private func waitForSemaphore(
  _ semaphore: DispatchSemaphore,
  timeout: DispatchTime
) async -> DispatchTimeoutResult {
  await withCheckedContinuation { continuation in
    DispatchQueue.global(qos: .userInitiated).async {
      continuation.resume(returning: semaphore.wait(timeout: timeout))
    }
  }
}

private final class PersistedStoreSnapshotGateProbe: @unchecked Sendable {
  private let lock = NSLock()
  private var attemptAt: Date?
  private var acquireAt: Date?
  private var mainActorProbeAt: Date?
  private var releaseAt: Date?
  private var probeCompletedBeforeRelease: Bool?

  func recordAttempt() {
    lock.lock()
    attemptAt = Date()
    lock.unlock()
  }

  func recordAcquire() {
    lock.lock()
    acquireAt = Date()
    lock.unlock()
  }

  func recordMainActorProbe() {
    lock.lock()
    mainActorProbeAt = Date()
    lock.unlock()
  }

  func recordRelease() {
    lock.lock()
    releaseAt = Date()
    lock.unlock()
  }

  func recordProbeCompletedBeforeRelease(_ value: Bool) {
    lock.lock()
    probeCompletedBeforeRelease = value
    lock.unlock()
  }

  func waitForAttempt(timeout: DispatchTime) -> Bool {
    while DispatchTime.now() < timeout {
      lock.lock()
      let didAttempt = attemptAt != nil
      lock.unlock()

      if didAttempt {
        return true
      }
      Thread.sleep(forTimeInterval: 0.001)
    }
    return false
  }

  func snapshot() -> (
    attemptAt: Date?,
    acquireAt: Date?,
    mainActorProbeAt: Date?,
    releaseAt: Date?,
    probeCompletedBeforeRelease: Bool?
  ) {
    lock.lock()
    defer { lock.unlock() }
    return (attemptAt, acquireAt, mainActorProbeAt, releaseAt, probeCompletedBeforeRelease)
  }
}
