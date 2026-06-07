// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Yoing",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "YoingCore", targets: ["YoingCore"]),
        .executable(name: "Yoing", targets: ["Yoing"])
    ],
    targets: [
        .target(
            name: "YoingCore",
            path: "Sources/YoingCore",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("Security")
            ]
        ),
        .executableTarget(
            name: "Yoing",
            dependencies: ["YoingCore"],
            path: "Sources/Yoing",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "YoingCoreTests",
            dependencies: ["YoingCore"],
            path: "Tests/YoingCoreTests"
        )
    ]
)
