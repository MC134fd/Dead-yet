// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DeadYet",
    platforms: [.iOS(.v17), .macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DeadYet",
            path: "Sources/DeadYet"
        ),
        .testTarget(
            name: "DeadYetTests",
            path: "Tests/DeadYetTests"
        ),
    ]
)
