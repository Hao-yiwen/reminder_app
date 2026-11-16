// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReminderAppModelTests",
    platforms: [
        .macOS(.v14),
    ],
    products: [],
    targets: [
        .target(
            name: "GoalModel",
            path: "reminder_app",
            exclude: [
                "Assets.xcassets",
                "Preview Content",
                "reminder_app.entitlements",
                "reminder_appApp.swift",
            ],
            sources: [
                "Goal.swift",
                "GoalsPersistence.swift",
            ]
        ),
        .testTarget(
            name: "GoalModelTests",
            dependencies: ["GoalModel"],
            path: "Tests/GoalModelTests"
        ),
    ]
)