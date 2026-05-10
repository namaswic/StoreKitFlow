// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StoreKitFlow",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "StoreKitFlow",
            targets: ["StoreKitFlow"]
        )
    ],
    targets: [
        .target(
            name: "StoreKitFlow",
            path: "Sources/StoreKitFlow"
        ),
        .testTarget(
            name: "StoreKitFlowTests",
            dependencies: ["StoreKitFlow"],
            path: "Tests/StoreKitFlowTests"
        )
    ]
)
