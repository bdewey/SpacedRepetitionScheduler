// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "HawLangPackage",
  platforms: [.iOS(.v16)],
  products: [
    .singleTargetLibrary("AppFeature"),
    .singleTargetLibrary("SpacedRepetitionFeature"),
  ],
  dependencies: [
    // MARK: Remote dependencies
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", branch: "observation-beta"),
    
    // MARK: Local dependencies
    .package(path: "/Users/daniellyons/Developer/My Swift Packages/Utilities"),
    .package(path: "/Users/daniellyons/Developer/Open Source/Apple Platforms Projects/SpacedRepetitionScheduler")
  ],
  targets: [
    .target(
      name: "AppFeature", dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]),
    .target(
      name: "SpacedRepetitionFeature",
      dependencies: [
        "Utilities",
        .product(name: "SpacedRepetitionScheduler", package: "spacedrepetitionscheduler"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    
      .testTarget(
        name: "SpacedRepetitionTests",
        dependencies: [
          "SpacedRepetitionFeature",
        ]
      )
  ]
)




extension Product {
  static func singleTargetLibrary(_ name: String) -> Product {
    .library(name: name, targets: [name])
  }
}
