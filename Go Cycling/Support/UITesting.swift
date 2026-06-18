//
//  UITesting.swift
//  Go Cycling
//

import Foundation

enum UITesting {
    // Keep UI tests black-box: the test target passes raw launch strings instead
    // of importing app support code.
    static let launchArgument = "-ui-testing"
    static let routeSaveFixtureArgument = "-ui-testing-route-save-fixture"
    static let routeSaveFixtureLaunchArguments = [
        launchArgument,
        routeSaveFixtureArgument,
    ]

    #if DEBUG
    // A real SQLite URL lets History fetch seeded rides, while the process-id
    // suffix keeps simultaneous UI-test runs from sharing a store.
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
