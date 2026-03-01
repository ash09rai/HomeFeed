// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HomeFeed",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "HomeFeed",
            targets: ["HomeFeed"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HomeFeed",
            dependencies: [],
            path: "HomeFeed",
            exclude: [
                "Info.plist"
            ],
            resources: [
                .process("Fonts"),
                .copy("Mocks/MockHomeFeedConfig.json"),
                .copy("Mocks/MockSectionResponse.json")
            ]
        ),
        .testTarget(
            name: "HomeFeedTests",
            dependencies: ["HomeFeed"],
            path: "HomeFeedTests",
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
