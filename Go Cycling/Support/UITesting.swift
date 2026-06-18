//
//  UITesting.swift
//  Go Cycling
//

import Foundation

enum UITesting {
    // UI tests stay black-box so they cannot link app-only helper code; raw
    // launch strings are the stable contract between test target and app.
    static let launchArgument = "-ui-testing"
    static let routeSaveFixtureArgument = "-ui-testing-route-save-fixture"
    static let routeSaveFixtureLaunchArguments = [
        launchArgument,
        routeSaveFixtureArgument,
    ]

    #if DEBUG
    // History fetches saved rides from Core Data, so UI smoke needs SQLite; the
    // process-id suffix keeps parallel smoke jobs from deleting each other's data.
    static let isolatedPersistenceStoreURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("GoCycling-\(ProcessInfo.processInfo.processIdentifier)-UITesting.sqlite")

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static func shouldUseIsolatedPersistence(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        arguments.contains(launchArgument)
    }

    static func shouldSeedRouteSaveFixture(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        shouldUseIsolatedPersistence(arguments: arguments) && arguments.contains(routeSaveFixtureArgument)
    }

    static var shouldRequestLocationAuthorization: Bool {
        !isEnabled
    }

    static var shouldShowUserLocation: Bool {
        !isEnabled
    }
    #else
    static let isolatedPersistenceStoreURL = URL(fileURLWithPath: "/dev/null")

    static var isEnabled: Bool { false }

    static func shouldUseIsolatedPersistence(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        false
    }

    static func shouldSeedRouteSaveFixture(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        false
    }

    static var shouldRequestLocationAuthorization: Bool { true }

    static var shouldShowUserLocation: Bool { true }
    #endif
}
