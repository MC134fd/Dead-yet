// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DeadYet",
    platforms: [.iOS(.v17), .macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "8.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "DeadYet",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            ],
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
