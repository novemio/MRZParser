// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "MRZParser",
    platforms: [.iOS(.v15), .macOS(.v11)],
    products: [
        .library(
            name: "MRZParser",
            targets: ["MRZParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.2"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", from: "1.3.3")
    ],
    targets: [
        .target(
            name: "MRZParser",
            dependencies: [
                .product(
                    name: "Dependencies",
                    package: "swift-dependencies"
                ),
            ]),
        .testTarget(
            name: "MRZParserTests",
            dependencies: [
                "MRZParser",
                .product(
                    name: "CustomDump",
                    package: "swift-custom-dump"
                )
            ]
        ),
    ]
)
