//
//  ActivityAwardsViewModelTests.swift
//  Go CyclingTests
//

import Combine
import Foundation
import Testing

@testable import Go_Cycling

@Suite("ActivityAwardsViewModel", .serialized)
@MainActor
struct ActivityAwardsViewModelTests {

  @Test("updates progress values and strings for locked awards")
  func updatesProgressValuesAndStringsForLockedAwards() async {
    let snapshots = await makeAwardsSnapshots()
    defer { snapshots.restore() }

    let records = CyclingRecords.shared
    records.unlockedIcons = [false, false, false, false, false, false]
    records.longestCyclingDistance = 5_000
    records.totalCyclingDistance = 50_000
    let subject = PassthroughSubject<Int, Never>()
    let viewModel = ActivityAwardsViewModel(recordsPublisher: subject.eraseToAnyPublisher())

    subject.send(1)

    #expect(viewModel.progressValues.map(Double.init) == [0.5, 0.2, 0.1, 0.5, 0.2, 0.1])
    #expect(
      viewModel.progressStrings == [
        "50.0% Complete",
        "20.0% Complete",
        "10.0% Complete",
        "50.0% Complete",
        "20.0% Complete",
        "10.0% Complete",
      ]
    )
    #expect(!viewModel.alertForNewIcon)
  }

  @Test("clamps over-threshold locked awards")
  func clampsOverThresholdLockedAwards() async {
    let snapshots = await makeAwardsSnapshots()
    defer { snapshots.restore() }

    let records = CyclingRecords.shared
    records.unlockedIcons = [false, false, false, false, false, false]
    records.longestCyclingDistance = 60_000
    records.totalCyclingDistance = 600_000
    let subject = PassthroughSubject<Int, Never>()
    let viewModel = ActivityAwardsViewModel(recordsPublisher: subject.eraseToAnyPublisher())

    subject.send(1)

    #expect(viewModel.progressValues.map(Double.init) == [1.0, 1.0, 1.0, 1.0, 1.0, 1.0])
    #expect(viewModel.progressStrings == [String](repeating: "100.0% Complete", count: 6))
  }

  @Test("presents unlocked awards and alerts once")
  func presentsUnlockedAwardsAndAlertsOnce() async {
    let snapshots = await makeAwardsSnapshots()
    defer { snapshots.restore() }

    let records = CyclingRecords.shared
    records.unlockedIcons = [true, false, true, false, false, true]
    let subject = PassthroughSubject<Int, Never>()
    let viewModel = ActivityAwardsViewModel(recordsPublisher: subject.eraseToAnyPublisher())

    subject.send(1)

    #expect(viewModel.progressValues[0] == 1.0)
    #expect(viewModel.progressValues[2] == 1.0)
    #expect(viewModel.progressValues[5] == 1.0)
    #expect(viewModel.progressStrings[0] == "100% Complete")
    #expect(viewModel.progressStrings[2] == "100% Complete")
    #expect(viewModel.progressStrings[5] == "100% Complete")
    #expect(viewModel.alertForNewIcon)
    #expect(UserDefaults.standard.bool(forKey: "alertedBronze1"))
    #expect(UserDefaults.standard.bool(forKey: "alertedGold1"))
    #expect(UserDefaults.standard.bool(forKey: "alertedGold2"))

    viewModel.resetAlert()
    #expect(!viewModel.alertForNewIcon)
  }

  @Test("does not repeat alerts for already-alerted awards")
  func doesNotRepeatAlertsForAlreadyAlertedAwards() async {
    let snapshots = await makeAwardsSnapshots()
    defer { snapshots.restore() }

    for key in awardAlertKeys {
      UserDefaults.standard.set(true, forKey: key)
    }
    let records = CyclingRecords.shared
    records.unlockedIcons = [true, true, true, true, true, true]
    let subject = PassthroughSubject<Int, Never>()
    let viewModel = ActivityAwardsViewModel(recordsPublisher: subject.eraseToAnyPublisher())

    subject.send(1)

    #expect(viewModel.progressValues.map(Double.init) == [1.0, 1.0, 1.0, 1.0, 1.0, 1.0])
    #expect(viewModel.progressStrings == [String](repeating: "100% Complete", count: 6))
    #expect(!viewModel.alertForNewIcon)
  }

  @Test("uses injected records when updating awards")
  func usesInjectedRecordsWhenUpdatingAwards() async {
    let snapshots = await makeAwardsSnapshots()
    defer { snapshots.restore() }

    let sharedRecords = CyclingRecords.shared
    sharedRecords.unlockedIcons = [false, false, false, false, false, false]
    sharedRecords.longestCyclingDistance = 0
    sharedRecords.totalCyclingDistance = 0

    let selectedRecords = CyclingRecords(arguments: [UITesting.launchArgument])
    selectedRecords.unlockedIcons = [false, false, false, false, false, false]
    selectedRecords.longestCyclingDistance = 25_000
    selectedRecords.totalCyclingDistance = 250_000

    let subject = PassthroughSubject<Int, Never>()
    let viewModel = ActivityAwardsViewModel(
      records: selectedRecords,
      recordsPublisher: subject.eraseToAnyPublisher()
    )

    subject.send(1)

    #expect(viewModel.progressValues.map(Double.init) == [1.0, 1.0, 0.5, 1.0, 1.0, 0.5])
  }

  @Test("returns medal order and localized award names")
  func returnsMedalOrderAndAwardNames() async {
    let snapshots = await makeAwardsSnapshots()
    defer { snapshots.restore() }

    let viewModel = ActivityAwardsViewModel(
      recordsPublisher: Empty<Int, Never>().eraseToAnyPublisher())

    #expect(
      viewModel.medalOrder.map(medalName)
        == ["bronze", "silver", "gold", "bronze", "silver", "gold"])
    #expect(
      viewModel.getAwardName(index: 0, usingMetric: true)
        == "Cycle at least 10.0 km in a single route")
    #expect(
      viewModel.getAwardName(index: 3, usingMetric: false)
        == "Cycle a total of at least 62.14 mi"
    )
  }
}

private let awardAlertKeys = [
  "alertedBronze1",
  "alertedSilver1",
  "alertedGold1",
  "alertedBronze2",
  "alertedSilver2",
  "alertedGold2",
]

private let awardsStoreKeys =
  cyclingRecordStoreKeys
  + awardAlertKeys
  + [
    iCloudSyncPreferenceKey,
    ReviewManager.reviewCountKey,
    ReviewManager.reviewRequestVersionKey,
    ReviewManager.completedRouteKey,
  ]

@MainActor
private struct AwardsSnapshots {
  let stores: PersistedStoreSnapshot
  let records: CyclingRecordsStateSnapshot

  func restore() {
    records.restore()
    stores.restore()
  }
}

@MainActor
private struct CyclingRecordsStateSnapshot {
  private let records: CyclingRecords
  private let totalCyclingTime: Double
  private let totalCyclingRoutes: Int
  private let unlockedIcons: [Bool]
  private let longestCyclingDistance: Double
  private let longestCyclingTime: Double
  private let fastestAverageSpeed: Double
  private let fastestAverageSpeedDate: Date?
  private let longestCyclingDistanceDate: Date?
  private let longestCyclingTimeDate: Date?
  private let totalCyclingDistance: Double

  init(records: CyclingRecords) {
    self.records = records
    totalCyclingTime = records.totalCyclingTime
    totalCyclingRoutes = records.totalCyclingRoutes
    unlockedIcons = records.unlockedIcons
    longestCyclingDistance = records.longestCyclingDistance
    longestCyclingTime = records.longestCyclingTime
    fastestAverageSpeed = records.fastestAverageSpeed
    fastestAverageSpeedDate = records.fastestAverageSpeedDate
    longestCyclingDistanceDate = records.longestCyclingDistanceDate
    longestCyclingTimeDate = records.longestCyclingTimeDate
    totalCyclingDistance = records.totalCyclingDistance
  }

  func restore() {
    records.totalCyclingTime = totalCyclingTime
    records.totalCyclingRoutes = totalCyclingRoutes
    records.unlockedIcons = unlockedIcons
    records.longestCyclingDistance = longestCyclingDistance
    records.longestCyclingTime = longestCyclingTime
    records.fastestAverageSpeed = fastestAverageSpeed
    records.fastestAverageSpeedDate = fastestAverageSpeedDate
    records.longestCyclingDistanceDate = longestCyclingDistanceDate
    records.longestCyclingTimeDate = longestCyclingTimeDate
    records.totalCyclingDistance = totalCyclingDistance
  }
}

@MainActor
private func makeAwardsSnapshots() async -> AwardsSnapshots {
  let snapshots = AwardsSnapshots(
    stores: await PersistedStoreSnapshot(keys: awardsStoreKeys),
    records: CyclingRecordsStateSnapshot(records: CyclingRecords.shared)
  )
  UserDefaults.standard.set(false, forKey: ReviewManager.completedRouteKey)
  return snapshots
}

private func medalName(_ medal: Medal) -> String {
  switch medal {
  case .bronze:
    return "bronze"
  case .silver:
    return "silver"
  case .gold:
    return "gold"
  }
}
