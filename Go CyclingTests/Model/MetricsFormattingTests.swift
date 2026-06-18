//
//  MetricsFormattingTests.swift
//  Go CyclingTests
//

import CoreLocation
import Foundation
import Testing

@testable import Go_Cycling

@Suite("MetricsFormatting")
struct MetricsFormattingTests {

  @Test("formats metric and imperial distances")
  func formatsDistances() {
    #expect(MetricsFormatting.formatDistance(distance: 1234, usingMetric: true) == "1.23 km")
    #expect(MetricsFormatting.formatDistance(distance: 1609.344, usingMetric: false) == "1.0 mi")
    #expect(
      MetricsFormatting.formatDistanceWithoutUnits(distance: 1234, usingMetric: true) == "1.23")
    #expect(
      MetricsFormatting.formatDistanceWithoutUnits(distance: 1609.344, usingMetric: false) == "1.0")
  }

  @Test("formats elapsed time")
  func formatsElapsedTime() {
    #expect(MetricsFormatting.formatTime(time: 0) == " 0s")
    #expect(MetricsFormatting.formatTime(time: 65) == " 1m 5s")
    #expect(MetricsFormatting.formatTime(time: 3661) == "1h 1m 1s")
  }

  @Test("formats live elapsed timer")
  func formatsLiveElapsedTimer() {
    #expect(MetricsFormatting.formatElapsedTimer(time: 0) == "00:00:00")
    #expect(MetricsFormatting.formatElapsedTimer(time: 65) == "00:01:05")
    #expect(MetricsFormatting.formatElapsedTimer(time: 3_661) == "01:01:01")
    #expect(MetricsFormatting.formatElapsedTimer(time: 90_305) == "25:05:05")
  }

  @Test("formats average speed from route distance and time")
  func formatsAverageSpeed() {
    let speeds: [CLLocationSpeed] = [5, 6, 7]

    #expect(
      MetricsFormatting.formatAverageSpeed(
        speeds: speeds,
        distance: 3_600,
        time: 600,
        usingMetric: true
      ) == "21.6 km/h"
    )
    #expect(
      MetricsFormatting.formatAverageSpeed(
        speeds: speeds,
        distance: 3_600,
        time: 600,
        usingMetric: false
      ) == "13.42 mph"
    )
  }

  @Test("falls back to speed samples when average speed would exceed top speed")
  func fallsBackToSpeedSamplesWhenAverageSpeedExceedsTopSpeed() {
    #expect(
      MetricsFormatting.formatAverageSpeed(
        speeds: [1, 2, 3],
        distance: 10_000,
        time: 100,
        usingMetric: true
      ) == "7.2 km/h"
    )
  }

  @Test("formats top speed and single speed")
  func formatsSpeeds() {
    #expect(MetricsFormatting.formatTopSpeed(speeds: [2, 5, 3], usingMetric: true) == "18.0 km/h")
    #expect(MetricsFormatting.formatTopSpeed(speeds: [2, 5, 3], usingMetric: false) == "11.18 mph")
    #expect(MetricsFormatting.formatSingleSpeed(speed: 5, usingMetric: true) == "18.0 km/h")
    #expect(MetricsFormatting.formatSingleSpeed(speed: 5, usingMetric: false) == "11.18 mph")
  }

  @Test("formats current speed and clamps negative speed display")
  func formatsSpeedWithoutUnits() {
    #expect(MetricsFormatting.formatSpeedWithoutUnits(speed: -1, usingMetric: true) == "0.0")
    #expect(MetricsFormatting.formatSpeedWithoutUnits(speed: 5, usingMetric: true) == "18.0")
    #expect(MetricsFormatting.formatSpeedWithoutUnits(speed: 5, usingMetric: false) == "11.18")
  }

  @Test("formats elevation gain")
  func formatsElevationGain() {
    let elevations: [CLLocationDistance] = [10, 15, 12, 20]

    #expect(
      MetricsFormatting.formatElevation(elevations: elevations, usingMetric: true) == "13.0 m")
    #expect(
      MetricsFormatting.formatElevation(elevations: elevations, usingMetric: false) == "42.65 ft")
    #expect(
      MetricsFormatting.formatElevationWithoutUnits(elevation: 13, usingMetric: true) == "13.0")
    #expect(
      MetricsFormatting.formatElevationWithoutUnits(elevation: 13, usingMetric: false) == "42.65")
  }

  @Test("returns metric and imperial unit labels")
  func returnsUnitLabels() {
    #expect(MetricsFormatting.getDistanceUnits(usingMetric: true) == "km")
    #expect(MetricsFormatting.getDistanceUnits(usingMetric: false) == "mi")
    #expect(MetricsFormatting.getSpeedUnits(usingMetric: true) == "km/h")
    #expect(MetricsFormatting.getSpeedUnits(usingMetric: false) == "mph")
    #expect(MetricsFormatting.getElevationUnits(usingMetric: true) == "m")
    #expect(MetricsFormatting.getElevationUnits(usingMetric: false) == "ft")
  }
}
