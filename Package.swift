// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "VachaVox",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VachaVox", targets: ["VachaVox"])
    ],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.12.4"),
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.17.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.3.0")
    ],
    targets: [
        .executableTarget(
            name: "VachaVox",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio"),
                .product(name: "WhisperKit", package: "WhisperKit"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "VachaVoxTests",
            dependencies: ["VachaVox"]
        )
    ]
)
