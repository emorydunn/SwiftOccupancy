// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftOccupancy",
    platforms: [
        .macOS("10.15.4"),
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RoomOccupancyKit",
            targets: ["RoomOccupancyKit"]),
        .executable(
            name: "SwiftOccupancy",
            targets: ["SwiftOccupancy"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.12.0"),

        .package(url: "https://github.com/emorydunn/AMG88xx.swift.git", .branch("main")),

            .package(url: "https://github.com/matsune/swift-mqtt.git", from: "1.0.0")
//        .package(url: "https://github.com/PasiSalenius/LightMQTT.git", from: "1.0.0"),
//        .package(url: "https://github.com/emorydunn/MQTTKit.git", .branch("master"))
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RoomOccupancyKit",
            dependencies: [
                .product(name: "OpenCombineShim", package: "OpenCombine"),
                .product(name: "MQTT", package: "swift-mqtt"),
                "AMG88xx",
//                "MQTTKit"
                
            ]),
        .testTarget(
            name: "RoomOccupancyKitTests",
            dependencies: ["RoomOccupancyKit"]),
        .target(
            name: "SwiftOccupancy",
            dependencies: ["RoomOccupancyKit"]),
    ]
)
