//
//  UITesting.swift
//  Go Cycling
//

import Foundation

enum UITesting {
    static let launchArgument = "-ui-testing"

    #if DEBUG
    private(set) static var isEnabled = false

    static func configureFromLaunchArguments() {
        isEnabled = ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static var shouldRequestLocationAuthorization: Bool {
        !isEnabled
    }
    #else
    static var isEnabled: Bool { false }

    static var shouldRequestLocationAuthorization: Bool { true }
    #endif
}
