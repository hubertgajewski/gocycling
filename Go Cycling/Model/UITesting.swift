//
//  UITesting.swift
//  Go Cycling
//

import Foundation

enum UITesting {
    static let launchArgument = "-ui-testing"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }
}
