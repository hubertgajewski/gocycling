//
//  UITesting.swift
//  Go Cycling
//

import Foundation

enum UITesting {
    static let launchArgument = "-ui-testing"

    #if DEBUG
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static var shouldRequestLocationAuthorization: Bool {
        !isEnabled
    }

    static var shouldShowUserLocation: Bool {
        !isEnabled
    }
    #else
    static var isEnabled: Bool { false }

    static var shouldRequestLocationAuthorization: Bool { true }

    static var shouldShowUserLocation: Bool { true }
    #endif
}
