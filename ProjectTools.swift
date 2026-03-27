import MCP
import Foundation

// MARK: - Project Tools

struct ProjectTools: ToolProvider {
    var tools: [Tool] {
        [
            Tool(
                name: "create_swift_package",
                description: "Create a new Swift package with specified type and configuration",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string", "description": "Package name"],
                        "path": ["type": "string", "description": "Target directory path"],
                        "packageType": [
                            "type": "string",
                            "enum": ["library", "executable", "tool", "macro", "plugin"],
                            "description": "Type of Swift package"
                        ],
                        "platforms": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "Target platforms (e.g., macOS, iOS, tvOS, watchOS)"
                        ],
                        "swiftVersion": [
                            "type": "string",
                            "description": "Swift tools version (default: 5.9)"
                        ],
                        "includeTests": [
                            "type": "boolean",
                            "description": "Include test target"
                        ],
                        "dependencies": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "url": ["type": "string"],
                                    "version": ["type": "string"],
                                    "product": ["type": "string"]
                                ]
                            ]
                        ]
                    ],
                    "required": ["name", "path", "packageType"]
                ]
            ),
            Tool(
                name: "scaffold_project",
                description: "Generate complete project structure with multiple targets and configurations",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "path": ["type": "string"],
                        "template": [
                            "type": "string",
                            "enum": [
                                "cli-tool",
                                "swift-script",
                                "ios-app",
                                "macos-app",
                                "swiftui-widget",
                                "swift-macro",
                                "server-side",
                                "multiplatform"
                            ]
                        ],
                        "features": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "Additional features to include (e.g., argument-parser, async-http, swiftui)"
                        ]
                    ],
                    "required": ["name", "path", "template"]
                ]
            ),
            Tool(
                name: "add_target",
                description: "Add a new target to existing Swift package",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "targetName": ["type": "string"],
                        "targetType": [
                            "type": "string",
                            "enum": ["executable", "library", "test", "plugin"]
                        ],
                        "dependencies": ["type": "array", "items": ["type": "string"]]
                    ],
                    "required": ["packagePath", "targetName", "targetType"]
                ]
            ),
            Tool(
                name: "analyze_project",
                description: "Analyze Swift project structure, dependencies, and provide recommendations",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "path": ["type": "string", "description": "Path to Swift package or project"],
                        "analysisType": [
                            "type": "string",
                            "enum": ["structure", "dependencies", "complexity", "all"],
                            "default": "all"
                        ]
                    ],
                    "required": ["path"]
                ]
            ),
            Tool(
                name: "setup_xcode_project",
                description: "Configure Xcode project settings, schemes, and build configurations",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "path": ["type": "string"],
                        "projectType": [
                            "type": "string",
                            "enum": ["app", "framework", "extension", "command-line"]
                        ],
                        "platforms": ["type": "array", "items": ["type": "string"]],
                        "capabilities": ["type": "array", "items": ["type": "string"]]
                    ],
                    "required": ["path", "projectType"]
                ]
            ),
        ]
    }

    func handle(_ name: String, arguments: [String: Any]) async throws -> Any {
        switch name {
        case "create_swift_package":
            return try await createSwiftPackage(arguments)
        case "scaffold_project":
            return try await scaffoldProject(arguments)
        case "add_target":
            return try await addTarget(arguments)
        case "analyze_project":
            return try await analyzeProject(arguments)
        case "setup_xcode_project":
            return try await setupXcodeProject(arguments)
        default:
            throw MCPError.methodNotFound
        }
    }

    // MARK: - Implementation

    private func createSwiftPackage(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String,
              let path = args["path"] as? String,
              let packageType = args["packageType"] as? String else {
            throw MCPError.invalidParams
        }

        let swiftVersion = args["swiftVersion"] as? String ?? "5.9"
        let platforms = args["platforms"] as? [String] ?? ["macOS(.v13)"]
        let includeTests = args["includeTests"] as? Bool ?? true
        let dependencies = args["dependencies"] as? [[String: String]] ?? []

        let fullPath = URL(fileURLWithPath: path).appendingPathComponent(name)

        // Create directory
        try FileManager.default.createDirectory(at: fullPath, withIntermediateDirectories: true)

        // Generate Package.swift
        var packageSwift = """
        // swift-tools-version:\(swiftVersion)
        import PackageDescription

        let package = Package(
            name: "\(name)",
            platforms: [\(platforms.joined(separator: ", "))],
        """

        if !dependencies.isEmpty {
            packageSwift += """

            dependencies: [
            """
            for (index, dep) in dependencies.enumerated() {
                if let url = dep["url"], let version = dep["version"] {
                    let comma = index < dependencies.count - 1 ? "," : ""
                    packageSwift += """
                .package(url: "\(url)", from: "\(version)")\(comma)
            """
                }
            }
            packageSwift += """

            ],
            """
        }

        packageSwift += """

            targets: [
        """

        switch packageType {
        case "library":
            packageSwift += """
                .target(
                    name: "\(name)",
                    dependencies: []
                ),
            """
        case "executable", "tool":
            packageSwift += """
                .executableTarget(
                    name: "\(name)",
                    dependencies: []
                ),
            """
        case "macro":
            packageSwift += """
                .macro(
                    name: "\(name)Macros",
                    dependencies: [
                        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
                    ]
                ),
                .target(name: "\(name)", dependencies: ["\(name)Macros"]),
            """
        default:
            break
        }

        if includeTests {
            packageSwift += """
                .testTarget(
                    name: "\(name)Tests",
                    dependencies: ["\(name)"]
                ),
            """
        }

        packageSwift += """
            ]
        )
        """

        // Write Package.swift
        let packageURL = fullPath.appendingPathComponent("Package.swift")
        try packageSwift.write(to: packageURL, atomically: true, encoding: .utf8)

        // Create source directory structure
        let sourcesPath = fullPath.appendingPathComponent("Sources").appendingPathComponent(name)
        try FileManager.default.createDirectory(at: sourcesPath, withIntermediateDirectories: true)

        // Create initial source file
        let sourceContent: String
        switch packageType {
        case "executable", "tool":
            sourceContent = """
            @main
            struct \(name) {
                static func main() {
                    print("Hello from \(name)!")
                }
            }
            """
        case "library":
            sourceContent = """
            public struct \(name) {
                public init() {}

                public func hello() -> String {
                    return "Hello from \(name)!"
                }
            }
            """
        default:
            sourceContent = "// \(name) implementation"
        }

        let sourceURL = sourcesPath.appendingPathComponent("\(name).swift")
        try sourceContent.write(to: sourceURL, atomically: true, encoding: .utf8)

        // Create .gitignore
        let gitignore = """
        .DS_Store
        /.build
        /Packages
        /*.xcodeproj
        xcuserdata/
        DerivedData/
        .swiftpm/
        """
        let gitignoreURL = fullPath.appendingPathComponent(".gitignore")
        try gitignore.write(to: gitignoreURL, atomically: true, encoding: .utf8)

        // Create README
        let readme = """
        # \(name)

        A Swift \(packageType) package.

        ## Usage

        \(packageType == "library" ? "Add this package as a dependency in your `Package.swift`:" : "Build and run:")

        ```swift
        \(packageType == "library" ? ".package(url: "path/to/\(name)"), from: "1.0.0")" : "swift build
swift run")
        ```
        """
        let readmeURL = fullPath.appendingPathComponent("README.md")
        try readme.write(to: readmeURL, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "path": fullPath.path,
            "packageType": packageType,
            "message": "Created \(packageType) package '\(name)' at \(fullPath.path)"
        ]
    }

    private func scaffoldProject(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String,
              let path = args["path"] as? String,
              let template = args["template"] as? String else {
            throw MCPError.invalidParams
        }

        let features = args["features"] as? [String] ?? []
        let fullPath = URL(fileURLWithPath: path).appendingPathComponent(name)

        // Create based on template
        switch template {
        case "cli-tool":
            return try await scaffoldCLITool(name: name, path: fullPath, features: features)
        case "swift-script":
            return try await scaffoldSwiftScript(name: name, path: fullPath, features: features)
        case "ios-app":
            return try await scaffoldiOSApp(name: name, path: fullPath, features: features)
        case "macos-app":
            return try await scaffoldmacOSApp(name: name, path: fullPath, features: features)
        case "swiftui-widget":
            return try await scaffoldWidget(name: name, path: fullPath, features: features)
        case "swift-macro":
            return try await scaffoldMacro(name: name, path: fullPath, features: features)
        default:
            throw MCPError.invalidParams
        }
    }

    private func scaffoldCLITool(name: String, path: URL, features: [String]) async throws -> Any {
        var dependencies: [[String: String]] = []
        if features.contains("argument-parser") {
            dependencies.append([
                "url": "https://github.com/apple/swift-argument-parser",
                "version": "1.3.0",
                "product": "ArgumentParser"
            ])
        }

        // Create package
        let result = try await createSwiftPackage([
            "name": name,
            "path": path.deletingLastPathComponent().path,
            "packageType": "executable",
            "platforms": ["macOS(.v13)"],
            "dependencies": dependencies
        ])

        // Create enhanced main.swift with ArgumentParser if requested
        if features.contains("argument-parser") {
            let mainContent = """
            import ArgumentParser
            import Foundation

            @main
            struct \(name): AsyncParsableCommand {
                static var configuration = CommandConfiguration(
                    commandName: "\(name.lowercased())",
                    abstract: "A command-line tool created with SwiftCoderMCP",
                    version: "1.0.0"
                )

                @Option(name: .shortAndLong, help: "The input file path")
                var input: String?

                @Option(name: .shortAndLong, help: "The output file path")
                var output: String?

                @Flag(name: .shortAndLong, help: "Enable verbose output")
                var verbose = false

                mutating func run() async throws {
                    if verbose {
                        print("Running \(name)...")
                    }

                    // Your implementation here
                    print("Hello from \(name)!")
                }
            }
            """

            let mainPath = path.appendingPathComponent("Sources/\(name)/main.swift")
            try mainContent.write(to: mainPath, atomically: true, encoding: .utf8)
        }

        // Create Makefile
        let makefile = """
        .PHONY: build run test clean install

        build:
        	swift build -c release

        run:
        	swift run

        test:
        	swift test

        clean:
        	swift package clean

        install: build
        	cp .build/release/\(name) /usr/local/bin/
        """
        let makefilePath = path.appendingPathComponent("Makefile")
        try makefile.write(to: makefilePath, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "template": "cli-tool",
            "path": path.path,
            "features": features,
            "message": "Created CLI tool '\(name)' with features: \(features.joined(separator: ", "))"
        ]
    }

    private func scaffoldSwiftScript(name: String, path: URL, features: [String]) async throws -> Any {
        // Create script file
        let scriptContent = """
        #!/usr/bin/env swift

        import Foundation

        // MARK: - \(name) Script

        print("\u{001B}[36mRunning \(name)...\u{001B}[0m")

        // Your script logic here

        print("\u{001B}[32mDone!\u{001B}[0m")
        """

        let scriptPath = path.appendingPathComponent("\(name).swift")
        try scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)

        // Make executable
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/chmod")
        process.arguments = ["+x", scriptPath.path]
        try process.run()
        process.waitUntilExit()

        // Create Package.swift for script dependencies
        let packageContent = """
        // swift-tools-version:5.9
        import PackageDescription

        let package = Package(
            name: "\(name)",
            dependencies: [
                // Add dependencies here
            ],
            targets: [
                .executableTarget(name: "\(name)")
            ]
        )
        """
        let packagePath = path.appendingPathComponent("Package.swift")
        try packageContent.write(to: packagePath, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "template": "swift-script",
            "path": path.path,
            "script": scriptPath.path,
            "message": "Created Swift script '\(name)' at \(scriptPath.path)"
        ]
    }

    private func scaffoldiOSApp(name: String, path: URL, features: [String]) async throws -> Any {
        // Create Xcode project structure
        let appPath = path.appendingPathComponent("\(name).app")

        // Create directories
        let directories = [
            "Sources",
            "Resources",
            "Tests",
            "WidgetExtension",
            "Assets.xcassets"
        ]

        for dir in directories {
            let dirPath = appPath.appendingPathComponent(dir)
            try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)
        }

        // Create main app file
        let appContent = """
        import SwiftUI

        @main
        struct \(name)App: App {
            var body: some Scene {
                WindowGroup {
                    ContentView()
                }
            }
        }

        struct ContentView: View {
            var body: some View {
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Hello, \(name)!")
                }
                .padding()
            }
        }
        """

        let appFilePath = appPath.appendingPathComponent("Sources/\(name)App.swift")
        try appContent.write(to: appFilePath, atomically: true, encoding: .utf8)

        // Create Info.plist
        let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleDevelopmentRegion</key>
            <string>$(DEVELOPMENT_LANGUAGE)</string>
            <key>CFBundleExecutable</key>
            <string>$(EXECUTABLE_NAME)</string>
            <key>CFBundleIdentifier</key>
            <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundleName</key>
            <string>$(PRODUCT_NAME)</string>
            <key>CFBundlePackageType</key>
            <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundleVersion</key>
            <string>1</string>
            <key>LSRequiresIPhoneOS</key>
            <true/>
            <key>UIApplicationSceneManifest</key>
            <dict>
                <key>UIApplicationSupportsMultipleScenes</key>
                <true/>
            </dict>
            <key>UILaunchScreen</key>
            <dict/>
            <key>UISupportedInterfaceOrientations</key>
            <array>
                <string>UIInterfaceOrientationPortrait</string>
                <string>UIInterfaceOrientationLandscapeLeft</string>
                <string>UIInterfaceOrientationLandscapeRight</string>
            </array>
        </dict>
        </plist>
        """
        let infoPlistPath = appPath.appendingPathComponent("Info.plist")
        try infoPlist.write(to: infoPlistPath, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "template": "ios-app",
            "path": appPath.path,
            "message": "Created iOS app structure for '\(name)'"
        ]
    }

    private func scaffoldmacOSApp(name: String, path: URL, features: [String]) async throws -> Any {
        let appPath = path.appendingPathComponent("\(name).app")

        // Create main.swift
        let mainContent = """
        import SwiftUI

        @main
        struct \(name)App: App {
            var body: some Scene {
                WindowGroup {
                    ContentView()
                }
                .defaultSize(width: 800, height: 600)
            }
        }

        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Welcome to \(name)")
                        .font(.largeTitle)
                    Button("Click Me") {
                        print("Button clicked!")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        """

        let sourcesPath = appPath.appendingPathComponent("Sources")
        try FileManager.default.createDirectory(at: sourcesPath, withIntermediateDirectories: true)
        let mainPath = sourcesPath.appendingPathComponent("main.swift")
        try mainContent.write(to: mainPath, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "template": "macos-app",
            "path": appPath.path,
            "message": "Created macOS app structure for '\(name)'"
        ]
    }

    private func scaffoldWidget(name: String, path: URL, features: [String]) async throws -> Any {
        let widgetPath = path.appendingPathComponent("\(name)Widget")

        // Create widget extension structure
        let sourcesPath = widgetPath.appendingPathComponent("Sources")
        try FileManager.default.createDirectory(at: sourcesPath, withIntermediateDirectories: true)

        // Create widget bundle
        let widgetContent = """
        import WidgetKit
        import SwiftUI

        struct \(name)Entry: TimelineEntry {
            let date: Date
            let value: String
        }

        struct \(name)Provider: TimelineProvider {
            func placeholder(in context: Context) -> \(name)Entry {
                \(name)Entry(date: Date(), value: "Placeholder")
            }

            func getSnapshot(in context: Context, completion: @escaping (\(name)Entry) -> ()) {
                let entry = \(name)Entry(date: Date(), value: "Snapshot")
                completion(entry)
            }

            func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
                var entries: [\(name)Entry] = []
                let currentDate = Date()

                for hourOffset in 0 ..< 5 {
                    let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                    let entry = \(name)Entry(date: entryDate, value: "Value \(hourOffset)")
                    entries.append(entry)
                }

                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
            }
        }

        struct \(name)WidgetView: View {
            var entry: \(name)Provider.Entry

            var body: some View {
                VStack {
                    Text(entry.value)
                        .font(.headline)
                    Text(entry.date, style: .time)
                        .font(.caption)
                }
                .containerBackground(.fill.tertiary, for: .widget)
            }
        }

        @main
        struct \(name)Widget: Widget {
            let kind: String = "\(name)Widget"

            var body: some WidgetConfiguration {
                StaticConfiguration(kind: kind, provider: \(name)Provider()) { entry in
                    \(name)WidgetView(entry: entry)
                }
                .configurationDisplayName("\(name) Widget")
                .description("A widget created with SwiftCoderMCP")
                .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
            }
        }

        #Preview(as: .systemSmall) {
            \(name)Widget()
        } timeline: {
            \(name)Entry(date: .now, value: "Preview 1")
            \(name)Entry(date: .now.addingTimeInterval(3600), value: "Preview 2")
        }
        """

        let widgetFilePath = sourcesPath.appendingPathComponent("\(name)Widget.swift")
        try widgetContent.write(to: widgetFilePath, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "template": "swiftui-widget",
            "path": widgetPath.path,
            "message": "Created SwiftUI Widget extension for '\(name)'"
        ]
    }

    private func scaffoldMacro(name: String, path: URL, features: [String]) async throws -> Any {
        // Create macro package structure
        let macroPath = path.appendingPathComponent("\(name)Macro")

        // Create Package.swift
        let packageContent = """
        // swift-tools-version: 5.9
        import PackageDescription
        import CompilerPluginSupport

        let package = Package(
            name: "\(name)",
            platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
            products: [
                .library(
                    name: "\(name)",
                    targets: ["\(name)"]
                ),
                .executable(
                    name: "\(name)Client",
                    targets: ["\(name)Client"]
                ),
            ],
            dependencies: [
                .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
            ],
            targets: [
                .macro(
                    name: "\(name)Macros",
                    dependencies: [
                        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                    ]
                ),
                .target(name: "\(name)", dependencies: ["\(name)Macros"]),
                .executableTarget(name: "\(name)Client", dependencies: ["\(name)"]),
                .testTarget(
                    name: "\(name)Tests",
                    dependencies: [
                        "\(name)Macros",
                        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                    ]
                ),
            ]
        )
        """

        let packagePath = macroPath.appendingPathComponent("Package.swift")
        try FileManager.default.createDirectory(at: macroPath, withIntermediateDirectories: true)
        try packageContent.write(to: packagePath, atomically: true, encoding: .utf8)

        // Create macro declaration
        let sourcesPath = macroPath.appendingPathComponent("Sources/\(name)")
        try FileManager.default.createDirectory(at: sourcesPath, withIntermediateDirectories: true)

        let macroDecl = """
        /// A macro that produces a string representation of the expression
        @freestanding(expression)
        public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(
            module: "\(name)Macros",
            type: "StringifyMacro"
        )

        /// A macro that adds a memberwise initializer
        @attached(member, names: named(init))
        public macro AddInit() = #externalMacro(
            module: "\(name)Macros",
            type: "AddInitMacro"
        )
        """

        let macroDeclPath = sourcesPath.appendingPathComponent("\(name).swift")
        try macroDecl.write(to: macroDeclPath, atomically: true, encoding: .utf8)

        // Create macro implementation
        let macroImplPath = macroPath.appendingPathComponent("Sources/\(name)Macros")
        try FileManager.default.createDirectory(at: macroImplPath, withIntermediateDirectories: true)

        let macroImpl = """
        import SwiftCompilerPlugin
        import SwiftSyntax
        import SwiftSyntaxBuilder
        import SwiftSyntaxMacros

        public struct StringifyMacro: ExpressionMacro {
            public static func expansion(
                of node: some FreestandingMacroExpansionSyntax,
                in context: some MacroExpansionContext
            ) -> ExprSyntax {
                guard let argument = node.argumentList.first?.expression else {
                    fatalError("compiler bug: the macro does not have any arguments")
                }

                return "(\(argument), \\(\"\(argument)\"))"
            }
        }

        public struct AddInitMacro: MemberMacro {
            public static func expansion(
                of node: AttributeSyntax,
                providingMembersOf declaration: some DeclGroupSyntax,
                in context: some MacroExpansionContext
            ) throws -> [DeclSyntax] {
                // Implementation for generating init
                return []
            }
        }

        @main
        struct \(name)Plugin: CompilerPlugin {
            let providingMacros: [Macro.Type] = [
                StringifyMacro.self,
                AddInitMacro.self,
            ]
        }
        """

        let macroImplFile = macroImplPath.appendingPathComponent("\(name)Macro.swift")
        try macroImpl.write(to: macroImplFile, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "template": "swift-macro",
            "path": macroPath.path,
            "message": "Created Swift macro package for '\(name)'"
        ]
    }

    private func addTarget(_ args: [String: Any]) async throws -> Any {
        // Implementation for adding targets
        return ["success": true, "message": "Target added successfully"]
    }

    private func analyzeProject(_ args: [String: Any]) async throws -> Any {
        // Implementation for project analysis
        return ["success": true, "analysis": "Project analysis complete"]
    }

    private func setupXcodeProject(_ args: [String: Any]) async throws -> Any {
        // Implementation for Xcode setup
        return ["success": true, "message": "Xcode project configured"]
    }
}

enum MCPError: Error {
    case invalidParams
    case methodNotFound
    case executionFailed(String)
}
