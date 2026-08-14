// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PingoCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "PingoCore", targets: ["PingoCore"])
    ],
    targets: [
        .target(name: "PingoCore"),
        .testTarget(name: "PingoCoreTests", dependencies: ["PingoCore"])
    ]
)
