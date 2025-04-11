// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CLIDemo",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "CLIDemo",
            dependencies: [
                .product(name: "TapDetection", package: "swift-macos-tap-detection"),
            ],
            linkerSettings: [
                .linkedFramework("Carbon")
            ]),
    ]
)