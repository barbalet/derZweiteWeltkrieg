// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DerZweiteWeltkrieg",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "DerZweiteWeltkriegCore",
            targets: ["DerZweiteWeltkriegCore"]
        ),
        .library(
            name: "DerZweiteWeltkriegAppUI",
            targets: ["DerZweiteWeltkriegAppUI"]
        ),
        .library(
            name: "DerZweiteWeltkriegGuderian",
            targets: ["DerZweiteWeltkriegGuderian"]
        ),
        .executable(
            name: "DerZweiteWeltkriegApp",
            targets: ["DerZweiteWeltkriegApp"]
        ),
        .executable(
            name: "DerZweiteWeltkriegTest",
            targets: ["DerZweiteWeltkriegTest"]
        ),
    ],
    targets: [
        .target(
            name: "DerZweiteWeltkriegCore",
            path: "Sources/DerZweiteWeltkriegCore",
            publicHeadersPath: "include",
            cSettings: [
                .define("HEINZ_GUDERIAN_GAME"),
            ]
        ),
        .target(
            name: "DerZweiteWeltkriegGuderian",
            dependencies: ["DerZweiteWeltkriegCore"],
            path: "Sources/DerZweiteWeltkriegGuderian"
        ),
        .target(
            name: "DerZweiteWeltkriegAppUI",
            dependencies: [
                "DerZweiteWeltkriegCore",
                "DerZweiteWeltkriegGuderian",
            ],
            path: "Sources/DerZweiteWeltkriegApp",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
            ]
        ),
        .executableTarget(
            name: "DerZweiteWeltkriegApp",
            dependencies: ["DerZweiteWeltkriegAppUI"],
            path: "Sources/DerZweiteWeltkriegAppHost",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
            ]
        ),
        .executableTarget(
            name: "DerZweiteWeltkriegTest",
            dependencies: ["DerZweiteWeltkriegAppUI"],
            path: "Sources/DerZweiteWeltkriegTest",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
            ]
        ),
        .testTarget(
            name: "DerZweiteWeltkriegTests",
            dependencies: [
                "DerZweiteWeltkriegCore",
                "DerZweiteWeltkriegGuderian",
            ],
            path: "Tests/DerZweiteWeltkriegTests"
        ),
    ]
)
