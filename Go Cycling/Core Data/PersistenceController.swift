//
//  PersistenceController.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-04-18.
//

import Foundation
import CoreData
import CoreLocation

struct PersistenceController {
    // A singleton for entire app to use
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false, arguments: [String] = ProcessInfo.processInfo.arguments) {
        container = NSPersistentCloudKitContainer(name: "GoCycling")
        
        guard let description = container.persistentStoreDescriptions.first else {
              fatalError("Failed to retrieve a persistent store description.")
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        for description in container.persistentStoreDescriptions {
            description.setOption(true as NSNumber, forKey:  NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
            // In-memory tests must not attach CloudKit; Core Data rejects CloudKit
            // mirroring for stores that are not backed by a normal SQLite URL.
            description.cloudKitContainerOptions = nil
        }
        else {
            #if DEBUG
            // The UI-smoke launch argument redirects persistence before the store
            // loads, so seeded rides cannot be written into the user's CloudKit store.
            let configuredForUITesting = PersistenceController.configureStoreForUITestingIfNeeded(
                description,
                arguments: arguments
            )
            if !configuredForUITesting && !Preferences.iCloudAvailable() {
                description.cloudKitContainerOptions = nil
            }
            #else
            if !Preferences.iCloudAvailable() {
                description.cloudKitContainerOptions = nil
            }
            #endif
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
                print("Preferences saved")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: Bike ride methods
    #if DEBUG
    @discardableResult
    static func configureStoreForUITestingIfNeeded(
        _ description: NSPersistentStoreDescription,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        storeURL: URL = UITesting.isolatedPersistenceStoreURL
    ) -> Bool {
        guard UITesting.shouldUseIsolatedPersistence(arguments: arguments) else { return false }

        // UI smoke needs a real SQLite store so History can fetch saved rides,
        // but it must be outside the app's normal CloudKit-backed database.
        description.url = storeURL
        description.cloudKitContainerOptions = nil
        return true
    }

    func isUsingPersistentStore(at expectedURL: URL) -> Bool {
        // The fixture deletes/reseeds rides; fail closed unless the loaded store
        // is the isolated UI-test store, never the user's production ride store.
        let expectedURL = Self.normalizedStoreURL(expectedURL)
        return container.persistentStoreCoordinator.persistentStores.contains { store in
            guard let storeURL = store.url else { return false }
            return Self.normalizedStoreURL(storeURL) == expectedURL
        }
    }

    private static func normalizedStoreURL(_ url: URL) -> URL {
        url.standardizedFileURL.resolvingSymlinksInPath()
    }
    #endif

    enum BikeRideStoreError: Error {
        // Route naming and record updates require a concrete saved BikeRide; if
        // Core Data cannot materialize it, callers must treat the save as failed.
        case savedRideUnavailable
    }

    func storeBikeRide(locations: [CLLocation?], speeds: [CLLocationSpeed?], distance: Double, elevations: [CLLocationDistance?], startTime: Date, time: Double, completion: @escaping (Result<BikeRide, Error>) -> Void) {
        // Copy value-type arrays before handing off to the background task
        let locationsCopy = locations
        let speedsCopy = speeds
        let elevationsCopy = elevations

        container.performBackgroundTask { context in
            var latitudes: [CLLocationDegrees] = []
            var longitudes: [CLLocationDegrees] = []
            var speedsValidated: [CLLocationSpeed] = []
            var elevationsValidated: [CLLocationDistance] = []

            for location in locationsCopy {
                // Only include coordinates where neither latitude nor longitude is nil
                if let currentLatitude = location?.coordinate.latitude {
                    if let currentLongitude = location?.coordinate.longitude {
                        latitudes.append(currentLatitude)
                        longitudes.append(currentLongitude)
                    }
                }
            }

            for speed in speedsCopy {
                // Only store non nil speeds
                if let currentSpeed = speed {
                    speedsValidated.append(currentSpeed)
                }
            }

            for elevation in elevationsCopy {
                // Only store non nil altitudes
                if let currentElevation = elevation {
                    elevationsValidated.append(currentElevation)
                }
            }

            let newBikeRide = BikeRide(context: context)
            newBikeRide.cyclingLatitudes = latitudes
            newBikeRide.cyclingLongitudes = longitudes
            newBikeRide.cyclingSpeeds = speedsValidated
            newBikeRide.cyclingDistance = distance
            newBikeRide.cyclingElevations = elevationsValidated
            newBikeRide.cyclingStartTime = startTime
            newBikeRide.cyclingTime = time
            // Default category
            newBikeRide.cyclingRouteName = "Uncategorized"

            do {
                try context.save()
                // Return the saved object in the view context so route naming targets
                // this ride instead of racing a "latest ride" fetch.
                let objectID = newBikeRide.objectID
                print("Bike ride saved")
                DispatchQueue.main.async {
                    do {
                        let savedRide = try container.viewContext.existingObject(with: objectID)
                        if let savedBikeRide = savedRide as? BikeRide {
                            completion(.success(savedBikeRide))
                        } else {
                            completion(.failure(BikeRideStoreError.savedRideUnavailable))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
            } catch {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Function to update the route name of a saved bike ride
    func updateBikeRideRouteName(existingBikeRide: BikeRide, latitudes: [CLLocationDegrees], longitudes: [CLLocationDegrees], speeds: [CLLocationSpeed], distance: Double, elevations: [CLLocationDistance], startTime: Date, time: Double, routeName: String) {
        let context = container.viewContext
        
        context.performAndWait {
            existingBikeRide.cyclingLatitudes = latitudes
            existingBikeRide.cyclingLongitudes = longitudes
            existingBikeRide.cyclingSpeeds = speeds
            existingBikeRide.cyclingDistance = distance
            existingBikeRide.cyclingElevations = elevations
            existingBikeRide.cyclingStartTime = startTime
            existingBikeRide.cyclingTime = time
            existingBikeRide.cyclingRouteName = routeName
            
            do {
                try context.save()
                print("Bike ride updated")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func deleteAllBikeRides() {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BikeRide")
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(fetchRequest)
            for managedObject in results {
                if let managedObjectData: NSManagedObject = managedObject as? NSManagedObject {
                    context.delete(managedObjectData)
                }
            }
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateBikeRideCategories(oldCategoriesToUpdate: [String], newCategoryNames: [String]) {
        let context = container.viewContext
        if (newCategoryNames.count > 0 && (newCategoryNames.count == oldCategoriesToUpdate.count)) {
            for (index, name) in newCategoryNames.enumerated() {
                let fetchRequest: NSFetchRequest<BikeRide> = BikeRide.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "cyclingRouteName == %@", oldCategoriesToUpdate[index])
                do {
                    let results = try context.fetch(fetchRequest)
                    for ride in results {
                        updateBikeRideRouteName(
                            existingBikeRide: ride,
                            latitudes: ride.cyclingLatitudes,
                            longitudes: ride.cyclingLongitudes,
                            speeds: ride.cyclingSpeeds,
                            distance: ride.cyclingDistance,
                            elevations: ride.cyclingElevations,
                            startTime: ride.cyclingStartTime,
                            time: ride.cyclingTime,
                            routeName: name)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    // Function to rename all routes of a given category to Uncategorized
    func removeCategory(categoryName: String) {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BikeRide> = BikeRide.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cyclingRouteName == %@", categoryName)
        do {
            let results = try context.fetch(fetchRequest)
            for ride in results {
                updateBikeRideRouteName(
                    existingBikeRide: ride,
                    latitudes: ride.cyclingLatitudes,
                    longitudes: ride.cyclingLongitudes,
                    speeds: ride.cyclingSpeeds,
                    distance: ride.cyclingDistance,
                    elevations: ride.cyclingElevations,
                    startTime: ride.cyclingStartTime,
                    time: ride.cyclingTime,
                    routeName: "Uncategorized")
            }
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: Records methods
    func storeRecords(totalDistance: Double, totalTime: Double, totalRoutes: Int64, unlockedIcons: [Bool], longestDistance: Double, longestTime: Double, fastestAvgSpeed: Double, longestDistanceDate: Date?, longestTimeDate: Date?, fastestAvgSpeedDate: Date?) {
        let context = container.viewContext
        
        let newRecords = Records(context: context)
        newRecords.totalCyclingDistance = totalDistance
        newRecords.totalCyclingTime = totalTime
        newRecords.totalCyclingRoutes = totalRoutes
        newRecords.unlockedIcons = unlockedIcons
        newRecords.longestCyclingDistance = longestDistance
        newRecords.longestCyclingTime = longestTime
        newRecords.fastestAverageSpeed = fastestAvgSpeed
        newRecords.longestCyclingDistanceDate = longestDistanceDate
        newRecords.longestCyclingTimeDate = longestTimeDate
        newRecords.fastestAverageSpeedDate = fastestAvgSpeedDate
        
        // Update unlocked icons array
        newRecords.setUnlockedIcons()
        
        do {
            try context.save()
            print("Records saved")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // Only need to store one records object, use this method to update the existing object
    func updateRecords(existingRecords: Records, totalDistance: Double, totalTime: Double, totalRoutes: Int64, longestDistance: Double, longestTime: Double, fastestAvgSpeed: Double, longestDistanceDate: Date?, longestTimeDate: Date?, fastestAvgSpeedDate: Date?) {
        let context = container.viewContext
        
        context.performAndWait {
            existingRecords.totalCyclingDistance = totalDistance
            existingRecords.totalCyclingTime = totalTime
            existingRecords.totalCyclingRoutes = totalRoutes
            existingRecords.longestCyclingDistance = longestDistance
            existingRecords.longestCyclingTime = longestTime
            existingRecords.fastestAverageSpeed = fastestAvgSpeed
            existingRecords.longestCyclingDistanceDate = longestDistanceDate
            existingRecords.longestCyclingTimeDate = longestTimeDate
            existingRecords.fastestAverageSpeedDate = fastestAvgSpeedDate
            
            // Update unlocked icons array
            existingRecords.setUnlockedIcons()
            
            do {
                try context.save()
                print("Records updated")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
