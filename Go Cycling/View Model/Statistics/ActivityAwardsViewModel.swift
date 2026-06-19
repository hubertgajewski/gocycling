//
//  ActivityAwardsViewModel.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-08-31.
//

import Foundation
import SwiftUI
import CoreData
import Combine

class ActivityAwardsViewModel: ObservableObject {

    // Awards used to read CyclingRecords.shared directly; holding the source
    // records lets isolated UI-test launches display their selected record state.
    private var sourceRecords: CyclingRecords?
    // Award-alert flags are stored in UserDefaults for production records, but
    // isolated launch records can only raise transient UI state.
    private var persistAwardAlerts = false

    @Published var progressValues: [CGFloat] = [CGFloat].init(repeating: 0.0, count: 6)
    @Published var unlockedIcons: [Bool] = [Bool].init(
        repeating: false,
        count: CyclingRecords.awardValues.count
    )
    @Published var progressStrings: [String] = [String].init(repeating: "0% Complete", count: 6)
    
    // Boolean to display alert for newly unlocked icon
    @Published var alertForNewIcon = false
    
    @Published var records: CyclingRecords? {
        willSet {
            // Recompute from the selected records object instead of the shared
            // singleton so injected launch storage drives every awards update.
            guard let updatedRecords = newValue ?? sourceRecords else { return }
            // Update published values when records change
            unlockedIcons = updatedRecords.unlockedIcons
            for index in 0..<CyclingRecords.awardValues.count {
                var progressFloat: CGFloat = 0.0
                // If icon is already unlocked then set progress to 100%
                if (unlockedIcons[index]) {
                    progressValues[index] = 1.0
                    progressStrings[index] = "100% Complete"
                    handleUnlockedAward(at: index)
                }
                // Single route awards
                else if (index < 3) {
                    let distance = updatedRecords.longestCyclingDistance
                    progressFloat = CGFloat(distance/CyclingRecords.awardValues[index]) > 1.0 ? 1.0 : CGFloat(distance/Records.awardValues[index])
                    progressValues[index] = progressFloat
                    let roundedProgress = round(progressFloat * 10000) / 100.0
                    progressStrings[index] = "\(roundedProgress)% Complete"
                }
                // Cummulative route awards
                else {
                    let distance = updatedRecords.totalCyclingDistance
                    progressFloat = CGFloat(distance/CyclingRecords.awardValues[index]) > 1.0 ? 1.0 : CGFloat(distance/Records.awardValues[index])
                    progressValues[index] = progressFloat
                    let roundedProgress = round(progressFloat * 10000) / 100.0
                    progressStrings[index] = "\(roundedProgress)% Complete"
                }
            }
        }
    }
    
    // Used by the activity awards view to display the correct medal for each award
    var medalOrder: [Medal] = [.bronze, .silver, .gold, .bronze, .silver, .gold]
    
    private var cancellable: AnyCancellable?

    // Tests can inject a publisher, but production binds to the selected records
    // object so award progress follows launch storage after environment injection.
    init(records: CyclingRecords? = nil, recordsPublisher: AnyPublisher<Int, Never>? = nil) {
        if let records = records {
            bindRecords(records, recordsPublisher: recordsPublisher)
        }
        
        // Launching statistics tab is a review worthy action
        ReviewManager.incrementReviewWorthyCount()
        
        // Request for review if appropriate
        ReviewManager.requestReviewIfAppropriate()
    }

    // Statistics supplies the launch-selected records after environment
    // injection so awards cannot drift to CyclingRecords.shared during UI tests.
    func useRecords(_ records: CyclingRecords) {
        alertForNewIcon = false
        bindRecords(records)
        self.records = records
    }

    private func bindRecords(
        _ records: CyclingRecords,
        recordsPublisher: AnyPublisher<Int, Never>? = nil
    ) {
        sourceRecords = records
        unlockedIcons = records.unlockedIcons
        persistAwardAlerts = records.writesPersistentState

        let publisher = recordsPublisher ?? records.$totalCyclingRoutes.eraseToAnyPublisher()
        cancellable = publisher.sink { [weak self] _ in
            guard let self = self else { return }
            print("Updating records")
            self.records = self.sourceRecords
        }
    }

    private static let awardAlertKeys = [
        "alertedBronze1",
        "alertedSilver1",
        "alertedGold1",
        "alertedBronze2",
        "alertedSilver2",
        "alertedGold2",
    ]

    private func handleUnlockedAward(at index: Int) {
        let key = Self.awardAlertKeys[index]
        if persistAwardAlerts {
            guard !UserDefaults.standard.bool(forKey: key) else { return }
            UserDefaults.standard.set(true, forKey: key)
        }
        alertForNewIcon = true
    }
    
    func getAwardName(index: Int, usingMetric: Bool) -> String {
        let distanceString = MetricsFormatting.formatDistance(distance: Records.awardValues[index], usingMetric: usingMetric)
        if (index < 3) {
            return "Cycle at least \(distanceString) in a single route"
        }
        else {
            return "Cycle a total of at least \(distanceString)"
        }
    }
    
    func resetAlert() {
        self.alertForNewIcon = false
    }
}
