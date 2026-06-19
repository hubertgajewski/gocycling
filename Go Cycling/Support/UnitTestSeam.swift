//
//  UnitTestSeam.swift
//  Go Cycling
//

import Foundation

/// DEBUG-only launch-argument hooks for Xcode unit tests. UI-smoke contracts live
/// in `UITesting`; unit-test availability seams stay here.
enum UnitTestSeam {
    static let simulateICloudAvailableLaunchArgument = "-simulate-icloud-available"

    static func shouldSimulateICloudAvailable(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> Bool {
        #if DEBUG
        arguments.contains(simulateICloudAvailableLaunchArgument)
        #else
        false
        #endif
    }
}
