// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DeadYet",
    platforms: [.iOS(.v17), .macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DeadYet",
            path: "Sources/DeadYet",
            swiftSettings: [.unsafeFlags(["-enable-testing"])]
        ),
        .testTarget(
            name: "DeadYetTests",
            dependencies: ["DeadYet"],
            path: "Tests/DeadYetTests",
            swiftSettings: [.unsafeFlags(["-enable-testing"])]
        ),
    ]
)
