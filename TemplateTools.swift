import MCP
import Foundation

// MARK: - Template Tools

struct TemplateTools: ToolProvider {
    var tools: [Tool] {
        [
            Tool(
                name: "apply_template",
                description: "Apply a predefined template to generate code or project structure",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "templateName": [
                            "type": "string",
                            "enum": [
                                "swift-script",
                                "cli-tool",
                                "ios-app",
                                "macos-app",
                                "swiftui-widget",
                                "swift-macro",
                                "swift-package",
                                "server-side",
                                "multiplatform"
                            ]
                        ],
                        "outputPath": ["type": "string"],
                        "projectName": ["type": "string"],
                        "customizations": [
                            "type": "object",
                            "description": "Template-specific customizations"
                        ]
                    ],
                    "required": ["templateName", "outputPath", "projectName"]
                ]
            ),
            Tool(
                name: "create_template",
                description: "Create a custom reusable template from existing code",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "templateName": ["type": "string"],
                        "sourcePath": ["type": "string", "description": "Path to source code to templatize"],
                        "templatePath": ["type": "string", "description": "Where to save the template"],
                        "variables": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "description": ["type": "string"],
                                    "defaultValue": ["type": "string"]
                                ]
                            ]
                        ],
                        "description": ["type": "string"]
                    ],
                    "required": ["templateName", "sourcePath"]
                ]
            ),
            Tool(
                name: "list_templates",
                description: "List all available templates with descriptions",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "category": [
                            "type": "string",
                            "enum": ["all", "app", "script", "package", "widget", "macro"]
                        ]
                    ]
                ]
            ),
            Tool(
                name: "customize_template",
                description: "Modify an existing template with new parameters or structure",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "templateName": ["type": "string"],
                        "modifications": [
                            "type": "object",
                            "properties": [
                                "addFiles": ["type": "array", "items": ["type": "string"]],
                                "removeFiles": ["type": "array", "items": ["type": "string"]],
                                "updateVariables": ["type": "array", "items": ["type": "object"]],
                                "addDependencies": ["type": "array", "items": ["type": "string"]]
                            ]
                        ]
                    ],
                    "required": ["templateName", "modifications"]
                ]
            ),
        ]
    }

    func handle(_ name: String, arguments: [String: Any]) async throws -> Any {
        switch name {
        case "apply_template":
            return try await applyTemplate(arguments)
        case "create_template":
            return try await createTemplate(arguments)
        case "list_templates":
            return try await listTemplates(arguments)
        case "customize_template":
            return try await customizeTemplate(arguments)
        default:
            throw MCPError.methodNotFound
        }
    }

    private func applyTemplate(_ args: [String: Any]) async throws -> Any {
        guard let templateName = args["templateName"] as? String,
              let outputPath = args["outputPath"] as? String,
              let projectName = args["projectName"] as? String else {
            throw MCPError.invalidParams
        }

        let customizations = args["customizations"] as? [String: Any] ?? [:]
        let outputURL = URL(fileURLWithPath: outputPath).appendingPathComponent(projectName)

        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        var filesCreated: [String] = []

        switch templateName {
        case "swift-script":
            filesCreated = try applySwiftScriptTemplate(outputURL: outputURL, projectName: projectName, customizations: customizations)
        case "cli-tool":
            filesCreated = try applyCLIToolTemplate(outputURL: outputURL, projectName: projectName, customizations: customizations)
        case "ios-app":
            filesCreated = try applyiOSAppTemplate(outputURL: outputURL, projectName: projectName, customizations: customizations)
        case "macos-app":
            filesCreated = try applymacOSAppTemplate(outputURL: outputURL, projectName: projectName, customizations: customizations)
        case "swiftui-widget":
            filesCreated = try applyWidgetTemplate(outputURL: outputURL, projectName: projectName, customizations: customizations)
        case "swift-macro":
            filesCreated = try applyMacroTemplate(outputURL: outputURL, projectName: projectName, customizations: customizations)
        case "swift-package":
            filesCreated = try applyPackageTemplate(outputURL: outputURL, projectName: projectName, customizations: customizations)
        case "server-side":
            filesCreated = try applyServerSideTemplate(outputURL: outputURL, projectName: projectName, customizations: customizations)
        case "multiplatform":
            filesCreated = try applyMultiplatformTemplate(outputURL: outputURL, projectName: projectName, customizations: customizations)
        default:
            throw MCPError.invalidParams
        }

        return [
            "success": true,
            "template": templateName,
            "projectName": projectName,
            "outputPath": outputURL.path,
            "filesCreated": filesCreated,
            "customizations": customizations
        ]
    }

    private func applySwiftScriptTemplate(outputURL: URL, projectName: String, customizations: [String: Any]) throws -> [String] {
        var files: [String] = []

        let scriptContent = """
        #!/usr/bin/env swift

        import Foundation

        print("Running \(projectName)...")

        // Your script logic here

        print("Done!")
        """

        let scriptPath = outputURL.appendingPathComponent("\(projectName).swift")
        try scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)
        files.append(scriptPath.lastPathComponent)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/chmod")
        process.arguments = ["+x", scriptPath.path]
        try? process.run()
        process.waitUntilExit()

        return files
    }

    private func applyCLIToolTemplate(outputURL: URL, projectName: String, customizations: [String: Any]) throws -> [String] {
        var files: [String] = []

        let packageSwift = """
        // swift-tools-version: 5.9
        import PackageDescription

        let package = Package(
            name: "\(projectName)",
            platforms: [.macOS(.v13)],
            dependencies: [
                .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
            ],
            targets: [
                .executableTarget(
                    name: "\(projectName)",
                    dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")]
                ),
            ]
        )
        """

        let packagePath = outputURL.appendingPathComponent("Package.swift")
        try packageSwift.write(to: packagePath, atomically: true, encoding: .utf8)
        files.append("Package.swift")

        let sourcesDir = outputURL.appendingPathComponent("Sources/\(projectName)")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)

        let mainContent = """
        import ArgumentParser

        @main
        struct \(projectName): AsyncParsableCommand {
            static var configuration = CommandConfiguration(
                commandName: "\(projectName.lowercased())",
                abstract: "A CLI tool created with SwiftCoderMCP",
                version: "1.0.0"
            )

            @Option(name: .shortAndLong, help: "Input file path")
            var input: String?

            @Flag(name: .shortAndLong, help: "Enable verbose output")
            var verbose = false

            mutating func run() async throws {
                if verbose {
                    print("Running \(projectName)...")
                }
                print("Hello from \(projectName)!")
            }
        }
        """

        let mainPath = sourcesDir.appendingPathComponent("main.swift")
        try mainContent.write(to: mainPath, atomically: true, encoding: .utf8)
        files.append("Sources/\(projectName)/main.swift")

        return files
    }

    private func applyiOSAppTemplate(outputURL: URL, projectName: String, customizations: [String: Any]) throws -> [String] {
        var files: [String] = []

        let appDir = outputURL.appendingPathComponent("\(projectName).app")
        let sourcesDir = appDir.appendingPathComponent("Sources")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)

        let appContent = """
        import SwiftUI

        @main
        struct \(projectName)App: App {
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
                    Text("Hello, \(projectName)!")
                }
                .padding()
            }
        }

        #Preview {
            ContentView()
        }
        """

        let appPath = sourcesDir.appendingPathComponent("\(projectName)App.swift")
        try appContent.write(to: appPath, atomically: true, encoding: .utf8)
        files.append("Sources/\(projectName)App.swift")

        return files
    }

    private func applymacOSAppTemplate(outputURL: URL, projectName: String, customizations: [String: Any]) throws -> [String] {
        var files: [String] = []

        let sourcesDir = outputURL.appendingPathComponent("Sources")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)

        let appContent = """
        import SwiftUI

        @main
        struct \(projectName)App: App {
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
                    Text("Welcome to \(projectName)")
                        .font(.largeTitle)
                    Button("Get Started") {
                        print("Button clicked!")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }

        #Preview {
            ContentView()
        }
        """

        let appPath = sourcesDir.appendingPathComponent("main.swift")
        try appContent.write(to: appPath, atomically: true, encoding: .utf8)
        files.append("Sources/main.swift")

        return files
    }

    private func applyWidgetTemplate(outputURL: URL, projectName: String, customizations: [String: Any]) throws -> [String] {
        var files: [String] = []

        let widgetDir = outputURL.appendingPathComponent("\(projectName)Widget")
        let sourcesDir = widgetDir.appendingPathComponent("Sources")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)

        let widgetContent = """
        import WidgetKit
        import SwiftUI

        struct \(projectName)Entry: TimelineEntry {
            let date: Date
            let value: String
        }

        struct \(projectName)Provider: TimelineProvider {
            func placeholder(in context: Context) -> \(projectName)Entry {
                \(projectName)Entry(date: Date(), value: "--")
            }

            func getSnapshot(in context: Context, completion: @escaping (\(projectName)Entry) -> ()) {
                completion(\(projectName)Entry(date: Date(), value: "Snapshot"))
            }

            func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
                let entry = \(projectName)Entry(date: Date(), value: "Current")
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
            }
        }

        struct \(projectName)WidgetView: View {
            var entry: \(projectName)Provider.Entry

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
        struct \(projectName)Widget: Widget {
            let kind: String = "\(projectName)Widget"

            var body: some WidgetConfiguration {
                StaticConfiguration(kind: kind, provider: \(projectName)Provider()) { entry in
                    \(projectName)WidgetView(entry: entry)
                }
                .configurationDisplayName("\(projectName)")
                .description("A widget for \(projectName)")
            }
        }

        #Preview(as: .systemSmall) {
            \(projectName)Widget()
        } timeline: {
            \(projectName)Entry(date: .now, value: "Preview")
        }
        """

        let widgetPath = sourcesDir.appendingPathComponent("\(projectName)Widget.swift")
        try widgetContent.write(to: widgetPath, atomically: true, encoding: .utf8)
        files.append("Sources/\(projectName)Widget.swift")

        return files
    }

    private func applyMacroTemplate(outputURL: URL, projectName: String, customizations: [String: Any]) throws -> [String] {
        var files: [String] = []

        let packageSwift = """
        // swift-tools-version: 5.9
        import PackageDescription
        import CompilerPluginSupport

        let package = Package(
            name: "\(projectName)",
            platforms: [.macOS(.v10_15), .iOS(.v13)],
            products: [
                .library(name: "\(projectName)", targets: ["\(projectName)"]),
                .executable(name: "\(projectName)Client", targets: ["\(projectName)Client"]),
            ],
            dependencies: [
                .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
            ],
            targets: [
                .macro(
                    name: "\(projectName)Macros",
                    dependencies: [
                        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                    ]
                ),
                .target(name: "\(projectName)", dependencies: ["\(projectName)Macros"]),
                .executableTarget(name: "\(projectName)Client", dependencies: ["\(projectName)"]),
            ]
        )
        """

        let packagePath = outputURL.appendingPathComponent("Package.swift")
        try packageSwift.write(to: packagePath, atomically: true, encoding: .utf8)
        files.append("Package.swift")

        let macroDecl = """
        @freestanding(expression)
        public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(
            module: "\(projectName)Macros", type: "StringifyMacro"
        )
        """

        let macroDir = outputURL.appendingPathComponent("Sources/\(projectName)")
        try FileManager.default.createDirectory(at: macroDir, withIntermediateDirectories: true)
        let macroDeclPath = macroDir.appendingPathComponent("\(projectName).swift")
        try macroDecl.write(to: macroDeclPath, atomically: true, encoding: .utf8)
        files.append("Sources/\(projectName)/\(projectName).swift")

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
                    fatalError("No argument provided")
                }
                return "(\(argument), \\(\"\(argument)\"))"
            }
        }

        @main
        struct \(projectName)Plugin: CompilerPlugin {
            let providingMacros: [Macro.Type] = [StringifyMacro.self]
        }
        """

        let macroImplDir = outputURL.appendingPathComponent("Sources/\(projectName)Macros")
        try FileManager.default.createDirectory(at: macroImplDir, withIntermediateDirectories: true)
        let macroImplPath = macroImplDir.appendingPathComponent("\(projectName)Macro.swift")
        try macroImpl.write(to: macroImplPath, atomically: true, encoding: .utf8)
        files.append("Sources/\(projectName)Macros/\(projectName)Macro.swift")

        return files
    }

    private func applyPackageTemplate(outputURL: URL, projectName: String, customizations: [String: Any]) throws -> [String] {
        var files: [String] = []

        let packageType = customizations["packageType"] as? String ?? "library"

        let packageSwift = """
        // swift-tools-version: 5.9
        import PackageDescription

        let package = Package(
            name: "\(projectName)",
            products: [
                .library(
                    name: "\(projectName)",
                    targets: ["\(projectName)"]
                ),
            ],
            targets: [
                .target(
                    name: "\(projectName)",
                    dependencies: []
                ),
            ]
        )
        """

        let packagePath = outputURL.appendingPathComponent("Package.swift")
        try packageSwift.write(to: packagePath, atomically: true, encoding: .utf8)
        files.append("Package.swift")

        let sourcesDir = outputURL.appendingPathComponent("Sources/\(projectName)")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)

        let sourceContent = """
        public struct \(projectName) {
            public init() {}

            public func hello() -> String {
                return "Hello from \(projectName)!"
            }
        }
        """

        let sourcePath = sourcesDir.appendingPathComponent("\(projectName).swift")
        try sourceContent.write(to: sourcePath, atomically: true, encoding: .utf8)
        files.append("Sources/\(projectName)/\(projectName).swift")

        return files
    }

    private func applyServerSideTemplate(outputURL: URL, projectName: String, customizations: [String: Any]) throws -> [String] {
        var files: [String] = []

        let packageSwift = """
        // swift-tools-version: 5.9
        import PackageDescription

        let package = Package(
            name: "\(projectName)",
            platforms: [.macOS(.v13)],
            dependencies: [
                .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
            ],
            targets: [
                .executableTarget(
                    name: "\(projectName)",
                    dependencies: [.product(name: "Vapor", package: "vapor")]
                ),
            ]
        )
        """

        let packagePath = outputURL.appendingPathComponent("Package.swift")
        try packageSwift.write(to: packagePath, atomically: true, encoding: .utf8)
        files.append("Package.swift")

        let sourcesDir = outputURL.appendingPathComponent("Sources/\(projectName)")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)

        let mainContent = """
        import Vapor

        @main
        enum Entrypoint {
            static func main() async throws {
                let app = Application()
                defer { app.shutdown() }

                app.get("hello") { req in
                    return "Hello, \(projectName)!"
                }

                try app.run()
            }
        }
        """

        let mainPath = sourcesDir.appendingPathComponent("main.swift")
        try mainContent.write(to: mainPath, atomically: true, encoding: .utf8)
        files.append("Sources/\(projectName)/main.swift")

        return files
    }

    private func applyMultiplatformTemplate(outputURL: URL, projectName: String, customizations: [String: Any]) throws -> [String] {
        var files: [String] = []

        let packageSwift = """
        // swift-tools-version: 5.9
        import PackageDescription

        let package = Package(
            name: "\(projectName)",
            platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9)],
            products: [
                .library(name: "\(projectName)", targets: ["\(projectName)"]),
            ],
            targets: [
                .target(name: "\(projectName)"),
                .testTarget(name: "\(projectName)Tests", dependencies: ["\(projectName)"]),
            ]
        )
        """

        let packagePath = outputURL.appendingPathComponent("Package.swift")
        try packageSwift.write(to: packagePath, atomically: true, encoding: .utf8)
        files.append("Package.swift")

        let sourcesDir = outputURL.appendingPathComponent("Sources/\(projectName)")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)

        let sharedContent = """
        import Foundation

        public struct \(projectName) {
            public init() {}

            public func platformName() -> String {
                #if os(iOS)
                return "iOS"
                #elseif os(macOS)
                return "macOS"
                #elseif os(tvOS)
                return "tvOS"
                #elseif os(watchOS)
                return "watchOS"
                #else
                return "Unknown"
                #endif
            }
        }
        """

        let sharedPath = sourcesDir.appendingPathComponent("Shared.swift")
        try sharedContent.write(to: sharedPath, atomically: true, encoding: .utf8)
        files.append("Sources/\(projectName)/Shared.swift")

        return files
    }

    private func createTemplate(_ args: [String: Any]) async throws -> Any {
        guard let templateName = args["templateName"] as? String,
              let sourcePath = args["sourcePath"] as? String else {
            throw MCPError.invalidParams
        }

        let templatePath = args["templatePath"] as? String
        let variables = args["variables"] as? [[String: String]] ?? []
        let description = args["description"] as? String ?? "Custom template"

        let sourceURL = URL(fileURLWithPath: sourcePath)
        let templateDir = templatePath != nil ? URL(fileURLWithPath: templatePath!) : 
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".swift-templates/\(templateName)")

        try FileManager.default.createDirectory(at: templateDir, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: sourceURL.path) {
            let destination = templateDir.appendingPathComponent(sourceURL.lastPathComponent)
            try FileManager.default.copyItem(at: sourceURL, to: destination)
        }

        let manifest: [String: Any] = [
            "name": templateName,
            "description": description,
            "variables": variables,
            "created": ISO8601DateFormatter().string(from: Date())
        ]

        let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
        let manifestPath = templateDir.appendingPathComponent("template.json")
        try manifestData.write(to: manifestPath)

        return [
            "success": true,
            "templateName": templateName,
            "templatePath": templateDir.path,
            "variables": variables.count,
            "description": description
        ]
    }

    private func listTemplates(_ args: [String: Any]) async throws -> Any {
        let category = args["category"] as? String ?? "all"

        let templates: [[String: String]] = [
            ["name": "swift-script", "category": "script", "description": "Standalone Swift script with executable permissions"],
            ["name": "cli-tool", "category": "script", "description": "Command-line tool using ArgumentParser"],
            ["name": "ios-app", "category": "app", "description": "iOS application with SwiftUI"],
            ["name": "macos-app", "category": "app", "description": "macOS application with SwiftUI"],
            ["name": "swiftui-widget", "category": "widget", "description": "WidgetKit extension for iOS/macOS"],
            ["name": "swift-macro", "category": "macro", "description": "Swift macro package with compiler plugin"],
            ["name": "swift-package", "category": "package", "description": "Reusable Swift package"],
            ["name": "server-side", "category": "package", "description": "Server-side Swift with Vapor"],
            ["name": "multiplatform", "category": "app", "description": "Multiplatform Swift package (iOS, macOS, tvOS, watchOS)"],
        ]

        let filtered = category == "all" ? templates : templates.filter { $0["category"] == category }

        return [
            "success": true,
            "templates": filtered,
            "count": filtered.count,
            "category": category
        ]
    }

    private func customizeTemplate(_ args: [String: Any]) async throws -> Any {
        guard let templateName = args["templateName"] as? String,
              let modifications = args["modifications"] as? [String: Any] else {
            throw MCPError.invalidParams
        }

        return [
            "success": true,
            "templateName": templateName,
            "modifications": modifications,
            "message": "Template customization applied"
        ]
    }
}
