// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Murmur",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "Murmur", targets: ["Murmur"]),
    ],
    targets: [
        .target(
            name: "Murmur",
            resources: [.process("Shaders")]
        ),
        .testTarget(
            name: "MurmurTests",
            dependencies: ["Murmur"]
        ),
    ]
)
