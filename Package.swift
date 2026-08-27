// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-json",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "JSON", targets: ["JSON"]),
        .library(
            name: "JSON Foundation Integration",
            targets: ["JSON Foundation Integration"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-ietf/swift-rfc-8259.git", branch: "main"),
        .package(
            url: "https://github.com/swift-molecules/swift-parser.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-array.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-molecules/swift-buffer.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-buffer-linear.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-storage.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-memory-allocation.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-memory-small.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-byte.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-index.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ascii.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ascii-parser.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-coder.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-either.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-compositions/swift-async.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "JSON",
            dependencies: [
                .product(name: "RFC 8259", package: "swift-rfc-8259"),
                .product(name: "Parser Error", package: "swift-parser"),
                .product(name: "Array", package: "swift-array"),
                .product(name: "Array Small Primitive", package: "swift-array"),
                .product(name: "Buffer Primitive", package: "swift-buffer"),
                .product(
                    name: "Buffer Linear Primitive",
                    package: "swift-buffer-linear"
                ),
                .product(
                    name: "Buffer Linear",
                    package: "swift-buffer-linear"
                ),
                .product(name: "Storage Primitive", package: "swift-storage"),
                .product(
                    name: "Storage Contiguous",
                    package: "swift-storage"
                ),
                .product(
                    name: "Memory Allocator Primitive",
                    package: "swift-memory-allocation"
                ),
                .product(name: "Memory Small", package: "swift-memory-small"),
                .product(name: "Byte Primitive", package: "swift-byte"),
                .product(name: "Index", package: "swift-index"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(
                    name: "ASCII Decimal Parser",
                    package: "swift-ascii-parser"
                ),
                .product(name: "Coder", package: "swift-coder"),
                .product(name: "Either", package: "swift-either"),
                .product(name: "Async", package: "swift-async"),
            ]
        ),
        .target(
            name: "JSON Foundation Integration",
            dependencies: [
                "JSON",
                .product(name: "Coder", package: "swift-coder"),
            ]
        ),
        .testTarget(
            name: "JSON Tests",
            dependencies: [
                "JSON"
            ]
        ),
        .testTarget(
            name: "JSON Foundation Integration Tests",
            dependencies: [
                "JSON",
                "JSON Foundation Integration",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
