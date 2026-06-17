// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "GoCycling",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "GoCyclingCore", targets: ["Go_Cycling"])
  ],
  targets: [
    .target(
      name: "Go_Cycling",
      path: "Go Cycling/Model",
      exclude: [
        "AutoPauseState.swift",
        "Category.swift",
        "ColourChoice.swift",
        "CyclingRecords.swift",
        "CyclingStatus.swift",
        "IconNames.swift",
        "MapTypeChoice.swift",
        "Medal.swift",
        "Preferences.swift",
        "ReviewManager.swift",
        "SortChoice.swift",
        "TelemetryManager.swift",
        "UnitsChoice.swift",
      ],
      sources: [
        "MetricsFormatting.swift",
        "RecordsFormatting.swift",
      ]
    ),
    .testTarget(
      name: "Go_CyclingTests",
      dependencies: ["Go_Cycling"],
      path: "Go CyclingTests/Model",
      exclude: [
        "CyclingRecordsTests.swift",
        "PreferencesConversionTests.swift",
      ],
      sources: [
        "MetricsFormattingTests.swift",
        "RecordsFormattingTests.swift",
      ]
    ),
  ]
)
