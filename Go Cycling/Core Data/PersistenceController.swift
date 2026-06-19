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
            // Unit tests need in-memory stores, and Core Data rejects CloudKit
            // mirroring when the store is not backed by a normal SQLite URL.
            description.cloudKitContainerOptions = nil
        }
        else {
            #if DEBUG
            // UI-smoke tests need persistence redirected before the store loads so
            // seeded rides cannot be written into the user's CloudKit store.
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

        // UI-smoke tests need SQLite because History fetches saved rides from Core
        // Data, but CloudKit stays off so test rides cannot sync to the user.
        description.url = storeURL
        description.cloudKitContainerOptions = nil
        return true
    }

    func isUsingPersistentStore(at expectedURL: URL) -> Bool {
        // The UI fixture deletes/reseeds rides; tests need this guard so a
        // misconfigured launch cannot erase the user's production ride store.
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
        // Route-save tests need an explicit failure when Core Data does not return
        // a saved BikeRide; otherwise callers could update records or show naming
        // even though there is no concrete saved route to edit.
        case savedRideUnavailable
    }

    func storeBikeRide(locations: [CLLocation?], speeds: [CLLocationSpeed?], distance: Double, elevations: [CLLocationDistance?], startTime: Date, time: Double, completion: @escaping (Result<BikeRide, Error>) -> Void) {
        // Copy value-type arrays before handing off to the background task
        let payload = BikeRideStorePayload(
            locations: locations,
            speeds: speeds,
            distance: distance,
            elevations: elevations,
            startTime: startTime,
            time: time
        )

        container.performBackgroundTask { context in
            let newBikeRide = payload.insertBikeRide(in: context)

            do {
                try context.save()
                // Route-naming UI tests need the exact saved object in the view
                // context so naming targets this ride instead of racing a
                // "latest ride" fetch.
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
        Self.deleteAllBikeRides(in: container.viewContext)
    }

    // Settings receives the launch-selected context from SwiftUI; this overload
    // lets deletion follow that context instead of always using the shared store.
    static func deleteAllBikeRides(in context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "BikeRide", in: context)
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
        Self.updateBikeRideCategories(
            in: container.viewContext,
            oldCategoriesToUpdate: oldCategoriesToUpdate,
            newCategoryNames: newCategoryNames
        )
    }

    // Route naming receives the launch-selected context from SwiftUI; updating
    // the ride in its own context avoids falling back to PersistenceController.shared.
    static func updateBikeRideRouteName(existingBikeRide: BikeRide, routeName: String) {
        guard let context = existingBikeRide.managedObjectContext else { return }
        context.performAndWait {
            existingBikeRide.cyclingRouteName = routeName
            do {
                try context.save()
                print("Bike ride updated")
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    // Category editing can run from a view backed by an isolated UI-test store,
    // so bulk updates must fetch and save through that selected context.
    static func updateBikeRideCategories(
        in context: NSManagedObjectContext,
        oldCategoriesToUpdate: [String],
        newCategoryNames: [String]
    ) {
        if (newCategoryNames.count > 0 && (newCategoryNames.count == oldCategoriesToUpdate.count)) {
            for (index, name) in newCategoryNames.enumerated() {
                let fetchRequest: NSFetchRequest<BikeRide> = BikeRide.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "cyclingRouteName == %@", oldCategoriesToUpdate[index])
                do {
                    let results = try context.fetch(fetchRequest)
                    for ride in results {
                        Self.updateBikeRideRouteName(existingBikeRide: ride, routeName: name)
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

private struct BikeRideStorePayload {
    let latitudes: [CLLocationDegrees]
    let longitudes: [CLLocationDegrees]
    let speeds: [CLLocationSpeed]
    let distance: Double
    let elevations: [CLLocationDistance]
    let startTime: Date
    let time: Double

    init(
        locations: [CLLocation?],
        speeds: [CLLocationSpeed?],
        distance: Double,
        elevations: [CLLocationDistance?],
        startTime: Date,
        time: Double
    ) {
        var latitudes: [CLLocationDegrees] = []
        var longitudes: [CLLocationDegrees] = []
        var speedsValidated: [CLLocationSpeed] = []
        var elevationsValidated: [CLLocationDistance] = []

        for location in locations {
            // Only include coordinates where neither latitude nor longitude is nil.
            if let currentLatitude = location?.coordinate.latitude {
                if let currentLongitude = location?.coordinate.longitude {
                    latitudes.append(currentLatitude)
                    longitudes.append(currentLongitude)
                }
            }
        }

        for speed in speeds {
            if let currentSpeed = speed {
                speedsValidated.append(currentSpeed)
            }
        }

        for elevation in elevations {
            if let currentElevation = elevation {
                elevationsValidated.append(currentElevation)
            }
        }

        self.latitudes = latitudes
        self.longitudes = longitudes
        self.speeds = speedsValidated
        self.distance = distance
        self.elevations = elevationsValidated
        self.startTime = startTime
        self.time = time
    }

    func insertBikeRide(in context: NSManagedObjectContext) -> BikeRide {
        guard let entity = NSEntityDescription.entity(forEntityName: "BikeRide", in: context) else {
            fatalError("Missing BikeRide entity")
        }
        let newBikeRide = BikeRide(entity: entity, insertInto: context)
        newBikeRide.cyclingLatitudes = latitudes
        newBikeRide.cyclingLongitudes = longitudes
        newBikeRide.cyclingSpeeds = speeds
        newBikeRide.cyclingDistance = distance
        newBikeRide.cyclingElevations = elevations
        newBikeRide.cyclingStartTime = startTime
        newBikeRide.cyclingTime = time
        newBikeRide.cyclingRouteName = "Uncategorized"
        return newBikeRide
    }
}

struct ManagedObjectContextBikeRideStore: BikeRideStoring {
    let context: NSManagedObjectContext

    func storeBikeRide(
        locations: [CLLocation?],
        speeds: [CLLocationSpeed?],
        distance: Double,
        elevations: [CLLocationDistance?],
        startTime: Date,
        time: Double,
        completion: @escaping (Result<BikeRide, Error>) -> Void
    ) {
        let payload = BikeRideStorePayload(
            locations: locations,
            speeds: speeds,
            distance: distance,
            elevations: elevations,
            startTime: startTime,
            time: time
        )
        // MapView only receives launch-selected Core Data through the SwiftUI
        // environment; save on a private context for that selected store and
        // return the selected view-context object asynchronously so
        // MapView.updateUIView never blocks or mutates records inline.
        let complete: (Result<BikeRide, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        guard let persistentStoreCoordinator = context.persistentStoreCoordinator else {
            complete(.failure(PersistenceController.BikeRideStoreError.savedRideUnavailable))
            return
        }
        let selectedContext = context
        let saveContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        saveContext.persistentStoreCoordinator = persistentStoreCoordinator
        saveContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        let save = {
            let newBikeRide = payload.insertBikeRide(in: saveContext)

            do {
                try saveContext.save()
                let objectID = newBikeRide.objectID
                print("Bike ride saved")
                selectedContext.perform {
                    do {
                        let savedRide = try selectedContext.existingObject(with: objectID)
                        if let savedBikeRide = savedRide as? BikeRide {
                            complete(.success(savedBikeRide))
                        } else {
                            complete(.failure(PersistenceController.BikeRideStoreError.savedRideUnavailable))
                        }
                    } catch {
                        complete(.failure(error))
                    }
                }
            } catch {
                print(error.localizedDescription)
                complete(.failure(error))
            }
        }

        saveContext.perform(save)
    }
}
