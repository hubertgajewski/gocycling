//
//  UITesting.swift
//  Go Cycling
//

import Foundation

enum UITesting {
    static let launchArgument = "-ui-testing"
    static let routeSaveFixtureArgument = "-ui-testing-route-save-fixture"

    #if DEBUG
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static var shouldRunRouteSaveFixture: Bool {
        isEnabled && ProcessInfo.processInfo.arguments.contains(routeSaveFixtureArgument)
    }

    static var shouldRequestLocationAuthorization: Bool {
        !isEnabled
    }

    static var shouldShowUserLocation: Bool {
        !isEnabled
    }
    #else
    static var isEnabled: Bool { false }

    static var shouldRunRouteSaveFixture: Bool { false }

    static var shouldRequestLocationAuthorization: Bool { true }

    static var shouldShowUserLocation: Bool { true }
    #endif
}
