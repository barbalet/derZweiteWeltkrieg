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
        .executable(
            name: "DerZweiteWeltkriegApp",
            targets: ["DerZweiteWeltkriegApp"]
        ),
    ],
    targets: [
        .target(
            name: "DerZweiteWeltkriegCore",
            path: "Sources/DerZweiteWeltkriegCore",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "DerZweiteWeltkriegApp",
            dependencies: ["DerZweiteWeltkriegCore"],
            path: "Sources/DerZweiteWeltkriegApp",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
            ]
        ),
        .testTarget(
            name: "DerZweiteWeltkriegTests",
            dependencies: ["DerZweiteWeltkriegCore"],
            path: "Tests/DerZweiteWeltkriegTests"
        ),
    ]
)
