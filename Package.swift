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
      name: "Go_Cycling"
    ),
    .testTarget(
      name: "Go_CyclingTests",
      dependencies: ["Go_Cycling"]
    ),
  ]
)
