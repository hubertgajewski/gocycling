//
//  BikeRide+Extensions.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-04-25.
//

import Foundation
import CoreData

extension BikeRide {

    // Testability: route-name, category, sort, and chart date-window helpers are
    // covered by unit tests that seed rides in in-memory Core Data stores. The
    // zero-arg APIs keep production compatibility by using PersistenceController.shared;
    // selected UI/chart paths call context overloads so isolated launches never
    // open or write the app singleton store, which fails on CI when the store
    // config differs.
    
    static func allBikeRides(in context: NSManagedObjectContext) -> [BikeRide] {
        let fetchRequest: NSFetchRequest<BikeRide> = BikeRide.fetchRequest()
        do {
            let items = try context.fetch(fetchRequest)
            return items
        }
        catch let error as NSError {
            print("Error getting BikeRides: \(error.localizedDescription), \(error.userInfo)")
        }
        return [BikeRide]()
    }

    static func allBikeRides() -> [BikeRide] {
        allBikeRides(in: PersistenceController.shared.container.viewContext)
    }
    
    static func allBikeRidesSorted(
        from bikeRidesUnsorted: [BikeRide],
        sortingChoice: SortChoice
    ) -> [BikeRide] {
        var bikeRides: [BikeRide] = []
        switch sortingChoice {
        case .distanceAscending:
            bikeRides = BikeRide.sortByDistance(list: bikeRidesUnsorted, ascending: true)
        case .distanceDescending:
            bikeRides = BikeRide.sortByDistance(list: bikeRidesUnsorted, ascending: false)
        case .dateAscending:
            bikeRides = BikeRide.sortByDate(list: bikeRidesUnsorted, ascending: true)
        case .dateDescending:
            bikeRides = BikeRide.sortByDate(list: bikeRidesUnsorted, ascending: false)
        case .timeAscending:
            bikeRides = BikeRide.sortByTime(list: bikeRidesUnsorted, ascending: true)
        case .timeDescending:
            bikeRides = BikeRide.sortByTime(list: bikeRidesUnsorted, ascending: false)
        }
        return bikeRides
    }

    static func allBikeRidesSorted(from bikeRidesUnsorted: [BikeRide]) -> [BikeRide] {
        allBikeRidesSorted(
            from: bikeRidesUnsorted,
            sortingChoice: Preferences.shared.sortingChoiceConverted
        )
    }

    static func allBikeRidesSorted() -> [BikeRide] {
        allBikeRidesSorted(from: allBikeRides())
    }
    
    static func allRouteNames(from bikeRides: [BikeRide]) -> [String] {
        var uniqueNames: [String] = []

        for ride in bikeRides {
            if (uniqueNames.firstIndex(of: ride.cyclingRouteName) == nil) {
                if (ride.cyclingRouteName != "Uncategorized") {
                    uniqueNames.append(ride.cyclingRouteName)
                }
            }
        }
        
        return uniqueNames.sorted { $0.lowercased() < $1.lowercased() }
    }

    static func allRouteNames() -> [String] {
        allRouteNames(from: allBikeRides())
    }
    
    static func allCategories(from bikeRides: [BikeRide]) -> [Category] {
        let allBikeRides = bikeRides
        var categories: [Category] = []
        var names: [String] = []
        var numbers: [Int] = []
        var uncategorizedCounter = 0
        
        for ride in allBikeRides {
            if (names.firstIndex(of: ride.cyclingRouteName) == nil) {
                if (ride.cyclingRouteName != "Uncategorized") {
                    names.append(ride.cyclingRouteName)
                    numbers.append(1)
                }
                else {
                    uncategorizedCounter += 1
                }
            }
            else {
                numbers[names.firstIndex(of: ride.cyclingRouteName)!] += 1
            }
        }
        
        for (index, name) in names.enumerated() {
            categories.append(Category(name: name, number: numbers[index]))
        }
        
        // Sort the user created categories alphabeticaly
        categories = categories.sorted { $0.name.lowercased() < $1.name.lowercased() }
        
        if (uncategorizedCounter > 0) {
            categories.insert(Category(name: "Uncategorized", number: uncategorizedCounter), at: 0)
        }
        
        if (allBikeRides.count > 0) {
            categories.insert(Category(name: "All", number: allBikeRides.count), at: 0)
        }
        
        return categories
    }

    static func allCategories() -> [Category] {
        allCategories(from: allBikeRides())
    }
    
    // Functions to get data for the charts on the statistics tab
    // Bar-chart detail views load after SwiftUI injects the selected context, so
    // date-window fetches need context overloads instead of opening shared storage.
    static func bikeRidesInPastWeek(in context: NSManagedObjectContext) -> [BikeRide] {
        let fetchRequest: NSFetchRequest<BikeRide> = BikeRide.fetchRequestsWithDateRanges()[0] ?? BikeRide.fetchRequest()
        return bikeRides(matching: fetchRequest, in: context)
    }

    static func bikeRidesInPastWeek() -> [BikeRide] {
        bikeRidesInPastWeek(in: PersistenceController.shared.container.viewContext)
    }
    
    static func bikeRidesInPast5Weeks(in context: NSManagedObjectContext) -> [BikeRide] {
        let fetchRequest: NSFetchRequest<BikeRide> = BikeRide.fetchRequestsWithDateRanges()[2] ?? BikeRide.fetchRequest()
        return bikeRides(matching: fetchRequest, in: context)
    }

    static func bikeRidesInPast5Weeks() -> [BikeRide] {
        bikeRidesInPast5Weeks(in: PersistenceController.shared.container.viewContext)
    }

    static func bikeRidesInPast30Weeks(in context: NSManagedObjectContext) -> [BikeRide] {
        let fetchRequest: NSFetchRequest<BikeRide> = BikeRide.fetchRequestsWithDateRanges()[4] ?? BikeRide.fetchRequest()
        return bikeRides(matching: fetchRequest, in: context)
    }
    
    static func bikeRidesInPast30Weeks() -> [BikeRide] {
        bikeRidesInPast30Weeks(in: PersistenceController.shared.container.viewContext)
    }

    private static func bikeRides(
        matching fetchRequest: NSFetchRequest<BikeRide>,
        in context: NSManagedObjectContext
    ) -> [BikeRide] {
        do {
            let items = try context.fetch(fetchRequest)
            return items
        }
        catch let error as NSError {
            print("Error getting BikeRides: \(error.localizedDescription), \(error.userInfo)")
        }
        return [BikeRide]()
    }
}
