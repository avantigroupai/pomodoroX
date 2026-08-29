// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PomodoroX",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PomodoroXCore",
            targets: ["PomodoroXCore"]
        ),
        .executable(
            name: "PomodoroXApp",
            targets: ["PomodoroXApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PomodoroXCore",
            dependencies: [],
            path: "Sources/PomodoroXCore"
        ),
        .executableTarget(
            name: "PomodoroXApp",
            dependencies: ["PomodoroXCore"],
            path: "Sources/PomodoroXApp"
        ),
        .testTarget(
            name: "PomodoroXCoreTests",
            dependencies: ["PomodoroXCore"],
            path: "Tests/PomodoroXCoreTests"
        )
    ]
)
