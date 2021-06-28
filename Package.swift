// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SpacedRepetitionScheduler",
  products: [
    .library(
      name: "SpacedRepetitionScheduler",
      targets: ["SpacedRepetitionScheduler"]
    ),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "SpacedRepetitionScheduler",
      dependencies: []
    ),
    .testTarget(
      name: "SpacedRepetitionSchedulerTests",
      dependencies: ["SpacedRepetitionScheduler"]
    ),
  ]
)
