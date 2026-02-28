// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SeniorDesignBackend",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // Vapor
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // Swift NIO
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // AWS SDK
        .package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.30.0"),
    ],
    targets: [
        .executableTarget(
            name: "SeniorDesignBackend",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "AWSS3", package: "aws-sdk-swift"),
                .product(name: "AWSDynamoDB", package: "aws-sdk-swift"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SeniorDesignBackendTests",
            dependencies: [
                .target(name: "SeniorDesignBackend"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }