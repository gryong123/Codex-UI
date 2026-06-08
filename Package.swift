// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EnglishLearningAssistant",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "EnglishLearningAssistant",
            targets: ["EnglishLearningAssistant"]
        )
    ],
    targets: [
        .executableTarget(
            name: "EnglishLearningAssistant"
        ),
        .testTarget(
            name: "EnglishLearningAssistantTests",
            dependencies: ["EnglishLearningAssistant"]
        )
    ]
)
