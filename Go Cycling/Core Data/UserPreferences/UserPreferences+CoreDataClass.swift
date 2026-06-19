//
//  SavedPreferences+CoreDataClass.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-04-18.
//
//

import Foundation
import CoreData
import SwiftUI

@objc(UserPreferences)
public class UserPreferences: NSManagedObject {
    static func convertColourChoiceToUIColor(colour: ColourChoice) -> UIColor {
        switch colour {
        case .red:
            return UIColor.systemRed
        case .orange:
            return UIColor.systemOrange
        case .yellow:
            return UIColor.systemYellow
        case .green:
            return UIColor.systemGreen
        case .blue:
            return UIColor.systemBlue
        case .indigo:
            return UIColor.systemIndigo
        case .violet:
            return UIColor.systemPurple
        }
    }
}

extension UserPreferences {
    static func savedPreferences() -> UserPreferences? {
        savedPreferences(in: PersistenceController.shared.container.viewContext)
    }

    // App launch migration passes the selected store context here so UI-test
    // launches do not fall back to the production-backed shared context.
    static func savedPreferences(in context: NSManagedObjectContext) -> UserPreferences? {
        let fetchRequest: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        do {
            let items = try context.fetch(fetchRequest)
            if items.count > 0 {
                return items[0]
            }
            else {
                return nil
            }
        }
        catch let error as NSError {
            print("Error getting UserPreferences: \(error.localizedDescription), \(error.userInfo)")
        }
        return nil
    }
}
