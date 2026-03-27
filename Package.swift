// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftCoderMCP",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "swift-coder-mcp", targets: ["SwiftCoderMCP"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftCoderMCP",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MCP", package: "swift-sdk"),
            ]
        ),
        .testTarget(
            name: "SwiftCoderMCPTests",
            dependencies: ["SwiftCoderMCP"]
        ),
    ]
)
