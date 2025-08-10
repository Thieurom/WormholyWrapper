// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WormholyWrapper",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Wormholy",
            targets: ["Wormholy"]
        )
    ],
    targets: [
        .binaryTarget(name: "Wormholy", path: "bin/Wormholy.xcframework.zip")
    ]
)
