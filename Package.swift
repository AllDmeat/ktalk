// swift-tools-version: 6.2
import PackageDescription

// Warnings are errors on our own targets. Kept in the manifest rather than a global
// `-Xswiftc -warnings-as-errors`, so the generated layer can stay out of it; SwiftPM
// ignores these settings when ktalk is consumed as a dependency.
let strict: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .treatAllWarnings(as: .error),
]

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
        ),
        .package(
            url: "https://github.com/apple/swift-openapi-generator",
            from: "1.7.0"
        ),
        .package(
            url: "https://github.com/apple/swift-openapi-runtime",
            from: "1.7.0"
        ),
        .package(
            url: "https://github.com/apple/swift-openapi-urlsession",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/apple/swift-http-types",
            from: "1.3.0"
        ),
    ],
    targets: [
        // The generated `types` + `client`. Not `strict`: the generator emits unused
        // `public import`s, and its warnings are not ours to fix.
        .target(
            name: "KTalkAPI",
            dependencies: [
                .product(
                    name: "OpenAPIRuntime",
                    package: "swift-openapi-runtime"
                )
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ],
            plugins: [
                .plugin(
                    name: "OpenAPIGenerator",
                    package: "swift-openapi-generator"
                )
            ]
        ),
        .target(
            name: "KTalkSDK",
            dependencies: [
                "KTalkAPI",
                .product(
                    name: "OpenAPIRuntime",
                    package: "swift-openapi-runtime"
                ),
                .product(
                    name: "OpenAPIURLSession",
                    package: "swift-openapi-urlsession"
                ),
                .product(
                    name: "HTTPTypes",
                    package: "swift-http-types"
                ),
            ],
            swiftSettings: strict
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
            swiftSettings: strict
        ),
        .testTarget(
            name: "KTalkSDKTests",
            dependencies: [
                "KTalkSDK",
                "ktalk",
            ],
            resources: [
                .copy("Fixtures")
            ],
            swiftSettings: strict
        ),
    ]
)
