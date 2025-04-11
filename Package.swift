// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TapDetection",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "TapDetection",
            targets: ["TapDetection"]),
    ],
    targets: [
        .target(
            name: "TapDetection",
            dependencies: [],
            linkerSettings: [
                .linkedFramework("Carbon")
            ]),
        .testTarget(
            name: "TapDetectionTests",
            dependencies: ["TapDetection"]),
    ]
)