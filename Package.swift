// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MindmapDesktops",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "MindmapDesktops",
            targets: ["MindmapDesktops"]),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MindmapDesktops",
            dependencies: []),
        .testTarget(
            name: "MindmapDesktopsTests",
            dependencies: ["MindmapDesktops"]),
    ]
)