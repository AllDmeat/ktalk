// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "KTalkSDK",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "KTalkSDK",
            targets: ["KTalkSDK"]
        ),
        .executable(
            name: "ktalk",
            targets: ["ktalk"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.5.0"
        )
    ],
    targets: [
        .target(
            name: "KTalkSDK",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "ktalk",
            dependencies: [
                "KTalkSDK",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "KTalkSDKTests",
            dependencies: [
                "KTalkSDK",
                "ktalk",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
