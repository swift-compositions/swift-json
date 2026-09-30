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
            url: "https://github.com/swift-atoms/swift-parser.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-array.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-atoms/swift-buffer.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-buffer-linear.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-storage.git",
            branch: "main", traits: ["Generational", "Memory"]),
        .package(
            url: "https://github.com/swift-molecules/swift-memory-allocation.git",
            branch: "main", traits: ["MemorySmall", "MemoryAllocatorArena", "MemoryInline"]),
        .package(
            url: "https://github.com/swift-atoms/swift-byte.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-index.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-either.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-molecules/swift-async-stream.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-ascii.git", branch: "main", traits: ["Coder", "Parser", "Serializer"]),
        .package(url: "https://github.com/swift-atoms/swift-coder.git", branch: "main", traits: ["Carrier", "Map"]),
        .package(url: "https://github.com/swift-atoms/swift-ratio.git", branch: "main", traits: ["Bit", "Ordinal", "Difference"]),
        .package(url: "https://github.com/swift-atoms/swift-span.git", branch: "main", traits: ["Iterator"]),
        .package(url: "https://github.com/swift-atoms/swift-finite.git", branch: "main", traits: ["Tagged"]),
        .package(url: "https://github.com/swift-atoms/swift-memory.git", branch: "main", traits: ["Lock", "Map", "Shared", "Cursor"]),
    ],
    targets: [
        .target(
            name: "JSON",
            dependencies: [
                .product(name: "RFC 8259", package: "swift-rfc-8259"),
                .product(name: "Parser", package: "swift-parser"),
                .product(name: "Array", package: "swift-array"),
                .product(name: "Array Small Primitive", package: "swift-array"),
                .product(name: "Buffer", package: "swift-buffer"),
                .product(
                    name: "Buffer Linear Primitive",
                    package: "swift-buffer-linear"
                ),
                .product(
                    name: "Buffer Linear",
                    package: "swift-buffer-linear"
                ),
                .product(name: "Storage", package: "swift-storage"),
                .product(
                    name: "Memory Allocator",
                    package: "swift-memory-allocation"
                ),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Index", package: "swift-index"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Coder", package: "swift-coder"),
                .product(name: "Either", package: "swift-either"),
                .product(name: "Async Stream", package: "swift-async-stream"),
                .product(name: "Memory Small", package: "swift-memory-allocation"),
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
