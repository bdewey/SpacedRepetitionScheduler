// swift-tools-version:5.5

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
