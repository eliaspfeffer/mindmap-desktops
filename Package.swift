// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MindmapDesktops",
    platforms: [
        .macOS(.v13)
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
            dependencies: [],
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "MindmapDesktopsTests",
            dependencies: ["MindmapDesktops"]),
    ]
)