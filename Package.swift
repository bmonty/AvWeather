// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AvWeather",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "AvWeather",
            targets: ["AvWeather"]),
    ],
    targets: [
        .target(
            name: "AvWeather",
            dependencies: []),
        .testTarget(
            name: "AvWeatherTests",
            dependencies: ["AvWeather"]),
    ]
)
