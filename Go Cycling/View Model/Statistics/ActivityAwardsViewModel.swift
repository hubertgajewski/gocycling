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
    private var sourceRecords: CyclingRecords

    @Published var progressValues: [CGFloat] = [CGFloat].init(repeating: 0.0, count: 6)
    @Published var unlockedIcons: [Bool]
    @Published var progressStrings: [String] = [String].init(repeating: "0% Complete", count: 6)
    
    // Boolean to display alert for newly unlocked icon
    @Published var alertForNewIcon = false
    
    @Published var records: CyclingRecords? {
        willSet {
            // Recompute from the selected records object instead of the shared
            // singleton so injected launch storage drives every awards update.
            let updatedRecords = newValue ?? sourceRecords
            // Update published values when records change
            unlockedIcons = updatedRecords.unlockedIcons
            for index in 0..<CyclingRecords.awardValues.count {
                var progressFloat: CGFloat = 0.0
                // If icon is already unlocked then set progress to 100%
                if (unlockedIcons[index]) {
                    progressValues[index] = 1.0
                    progressStrings[index] = "100% Complete"
                    // Check if user has been alerted of this unlocked icon
                    switch index {
                    case 0:
                        if (!UserDefaults.standard.bool(forKey: "alertedBronze1")) {
                            UserDefaults.standard.set(true, forKey: "alertedBronze1")
                            alertForNewIcon = true
                        }
                    case 1:
                        if (!UserDefaults.standard.bool(forKey: "alertedSilver1")) {
                            UserDefaults.standard.set(true, forKey: "alertedSilver1")
                            alertForNewIcon = true
                        }
                    case 2:
                        if (!UserDefaults.standard.bool(forKey: "alertedGold1")) {
                            UserDefaults.standard.set(true, forKey: "alertedGold1")
                            alertForNewIcon = true
                        }
                    case 3:
                        if (!UserDefaults.standard.bool(forKey: "alertedBronze2")) {
                            UserDefaults.standard.set(true, forKey: "alertedBronze2")
                            alertForNewIcon = true
                        }
                    case 4:
                        if (!UserDefaults.standard.bool(forKey: "alertedSilver2")) {
                            UserDefaults.standard.set(true, forKey: "alertedSilver2")
                            alertForNewIcon = true
                        }
                    case 5:
                        if (!UserDefaults.standard.bool(forKey: "alertedGold2")) {
                            UserDefaults.standard.set(true, forKey: "alertedGold2")
                            alertForNewIcon = true
                        }
                    default:
                        fatalError("Index out of range")
                    }
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
    init(records: CyclingRecords = CyclingRecords.shared, recordsPublisher: AnyPublisher<Int, Never>? = nil) {
        self.sourceRecords = records
        self.unlockedIcons = records.unlockedIcons

        let publisher = recordsPublisher ?? records.$totalCyclingRoutes.eraseToAnyPublisher()
        cancellable = publisher.sink { [weak self] _ in
            guard let self = self else { return }
            print("Updating records")
            self.records = self.sourceRecords
        }
        
        // Launching statistics tab is a review worthy action
        ReviewManager.incrementReviewWorthyCount()
        
        // Request for review if appropriate
        ReviewManager.requestReviewIfAppropriate()
    }

    // Statistics supplies the launch-selected records after environment
    // injection so awards cannot drift to CyclingRecords.shared during UI tests.
    func useRecords(_ records: CyclingRecords) {
        sourceRecords = records
        unlockedIcons = records.unlockedIcons
        alertForNewIcon = false
        cancellable = records.$totalCyclingRoutes.sink { [weak self] _ in
            guard let self = self else { return }
            print("Updating records")
            self.records = self.sourceRecords
        }
        self.records = records
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
