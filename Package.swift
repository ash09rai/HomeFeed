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
    dependencies: [
        .package(url: "https://github.com/ash09rai/ZoomableImageManager.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "HomeFeed",
            dependencies: [
                .product(name: "ZoomableImageManager", package: "ZoomableImageManager")
            ],
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
