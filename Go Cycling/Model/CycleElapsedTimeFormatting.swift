//
//  CycleElapsedTimeFormatting.swift
//  Go Cycling
//

import Foundation

// Formats the live cycle-tab timer as zero-padded HH:mm:ss.
class CycleElapsedTimeFormatting {
    static func formatTimeString(accumulatedTime: TimeInterval) -> String {
        let hours = Int(accumulatedTime) / 3600
        let minutes = Int(accumulatedTime) / 60 % 60
        let seconds = Int(accumulatedTime) % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}
