// swift-tools-version:5.4

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
      dependencies: [],
      exclude: ["Documentation.docc"]
    ),
    .testTarget(
      name: "SpacedRepetitionSchedulerTests",
      dependencies: ["SpacedRepetitionScheduler"]
    ),
  ]
)
