import MCP
import Foundation

// MARK: - Script Tools

struct ScriptTools: ToolProvider {
    var tools: [Tool] {
        [
            Tool(
                name: "create_swift_script",
                description: "Create a standalone Swift script with shebang and executable permissions",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "path": ["type": "string"],
                        "content": ["type": "string", "description": "Script content"],
                        "dependencies": ["type": "array", "items": ["type": "string"], "description": "Swift Package dependencies"],
                        "arguments": ["type": "array", "items": ["type": "string"], "description": "Expected command-line arguments"],
                        "makeExecutable": ["type": "boolean", "default": true]
                    ],
                    "required": ["name", "path"]
                ]
            ),
            Tool(
                name: "create_shortcut_intent",
                description: "Create AppIntent for Shortcuts app integration",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "description": ["type": "string"],
                        "parameters": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "type": ["type": "string"],
                                    "description": ["type": "string"],
                                    "defaultValue": ["type": "any"]
                                ]
                            ]
                        ],
                        "returnType": ["type": "string"],
                        "performCode": ["type": "string", "description": "Code to execute when intent is performed"]
                    ],
                    "required": ["name", "description"]
                ]
            ),
            Tool(
                name: "create_cli_tool",
                description: "Create command-line tool using ArgumentParser",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "path": ["type": "string"],
                        "subcommands": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "description": ["type": "string"],
                                    "arguments": ["type": "array", "items": ["type": "object"]]
                                ]
                            ]
                        ],
                        "arguments": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "type": ["type": "string"],
                                    "help": ["type": "string"],
                                    "shortName": ["type": "string"],
                                    "defaultValue": ["type": "any"]
                                ]
                            ]
                        ],
                        "flags": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "help": ["type": "string"],
                                    "shortName": ["type": "string"]
                                ]
                            ]
                        ]
                    ],
                    "required": ["name", "path"]
                ]
            ),
            Tool(
                name: "create_automation_script",
                description: "Create macOS automation script using NSWorkspace, Apple Events, etc.",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "path": ["type": "string"],
                        "automationType": [
                            "type": "string",
                            "enum": ["file", "app", "system", "network", "clipboard"],
                            "description": "Type of automation"
                        ],
                        "actions": ["type": "array", "items": ["type": "string"], "description": "List of actions to perform"]
                    ],
                    "required": ["name", "path", "automationType"]
                ]
            ),
            Tool(
                name: "bundle_script",
                description: "Bundle Swift script as standalone executable with dependencies",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "scriptPath": ["type": "string"],
                        "outputPath": ["type": "string"],
                        "includeDependencies": ["type": "boolean", "default": true],
                        "stripSymbols": ["type": "boolean", "default": false]
                    ],
                    "required": ["scriptPath", "outputPath"]
                ]
            ),
        ]
    }

    func handle(_ name: String, arguments: [String: Any]) async throws -> Any {
        switch name {
        case "create_swift_script":
            return try await createSwiftScript(arguments)
        case "create_shortcut_intent":
            return try await createShortcutIntent(arguments)
        case "create_cli_tool":
            return try await createCLITool(arguments)
        case "create_automation_script":
            return try await createAutomationScript(arguments)
        case "bundle_script":
            return try await bundleScript(arguments)
        default:
            throw MCPError.methodNotFound
        }
    }

    // MARK: - Implementation

    private func createSwiftScript(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String,
              let path = args["path"] as? String else {
            throw MCPError.invalidParams
        }

        let content = args["content"] as? String
        let dependencies = args["dependencies"] as? [String] ?? []
        let arguments = args["arguments"] as? [String] ?? []
        let makeExecutable = args["makeExecutable"] as? Bool ?? true

        let scriptPath = URL(fileURLWithPath: path).appendingPathComponent("\(name).swift")

        var scriptContent = "#!/usr/bin/env swift

"

        // Add imports
        scriptContent += "import Foundation
"
        for dep in dependencies {
            scriptContent += "import \(dep)
"
        }
        scriptContent += "
"

        // Add argument handling if specified
        if !arguments.isEmpty {
            scriptContent += """
            // MARK: - Arguments

            let arguments = CommandLine.arguments.dropFirst()

            guard arguments.count >= \(arguments.count) else {
                print("Usage: \(name) \(arguments.map { "<\($0)>" }.joined(separator: " "))")
                exit(1)
            }

            """

            for (index, arg) in arguments.enumerated() {
                scriptContent += "let \(arg) = arguments.dropFirst(\(index)).first!
"
            }
            scriptContent += "
"
        }

        // Add main content
        if let customContent = content {
            scriptContent += customContent
        } else {
            scriptContent += """
            // MARK: - Main

            print("Hello from \(name)!")

            // Your script logic here

            """
        }

        try scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)

        // Make executable
        if makeExecutable {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/chmod")
            process.arguments = ["+x", scriptPath.path]
            try process.run()
            process.waitUntilExit()
        }

        return [
            "success": true,
            "scriptPath": scriptPath.path,
            "name": name,
            "isExecutable": makeExecutable,
            "dependencies": dependencies,
            "arguments": arguments
        ]
    }

    private func createShortcutIntent(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String,
              let description = args["description"] as? String else {
            throw MCPError.invalidParams
        }

        let parameters = args["parameters"] as? [[String: Any]] ?? []
        let returnType = args["returnType"] as? String ?? "Void"
        let performCode = args["performCode"] as? String ?? "// Perform action"

        var paramDeclarations = ""
        var paramBindings = ""

        for param in parameters {
            guard let paramName = param["name"] as? String,
                  let paramType = param["type"] as? String else { continue }

            let paramDesc = param["description"] as? String ?? paramName
            let defaultValue = param["defaultValue"]

            paramDeclarations += """

            @Parameter(title: "\(paramName.capitalized)", description: "\(paramDesc)")
            var \(paramName): \(paramType)?
            """

            paramBindings += "		\(paramName): \(\(paramName) ?? \(defaultValue != nil ? "\(defaultValue!)" : "nil"))
"
        }

        let intentCode = """
        import AppIntents
        import Foundation

        struct \(name)Intent: AppIntent {
            static var title: LocalizedStringResource = "\(name)"
            static var description = IntentDescription("\(description)")

        \(paramDeclarations)

            func perform() async throws -> some IntentResult {
                \(performCode)

                return .result()
            }
        }
        """

        return [
            "success": true,
            "code": intentCode,
            "intentName": "\(name)Intent",
            "parameters": parameters.count,
            "returnType": returnType
        ]
    }

    private func createCLITool(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String,
              let path = args["path"] as? String else {
            throw MCPError.invalidParams
        }

        let subcommands = args["subcommands"] as? [[String: Any]] ?? []
        let arguments = args["arguments"] as? [[String: Any]] ?? []
        let flags = args["flags"] as? [[String: Any]] ?? []

        let toolPath = URL(fileURLWithPath: path).appendingPathComponent(name)

        // Create Package.swift
        let packageSwift = """
        // swift-tools-version: 5.9
        import PackageDescription

        let package = Package(
            name: "\(name)",
            platforms: [.macOS(.v13)],
            dependencies: [
                .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
            ],
            targets: [
                .executableTarget(
                    name: "\(name)",
                    dependencies: [
                        .product(name: "ArgumentParser", package: "swift-argument-parser"),
                    ]
                ),
            ]
        )
        """

        let packagePath = toolPath.appendingPathComponent("Package.swift")
        try FileManager.default.createDirectory(at: toolPath, withIntermediateDirectories: true)
        try packageSwift.write(to: packagePath, atomically: true, encoding: .utf8)

        // Create main.swift
        let sourcesPath = toolPath.appendingPathComponent("Sources/\(name)")
        try FileManager.default.createDirectory(at: sourcesPath, withIntermediateDirectories: true)

        var mainContent = """
        import ArgumentParser
        import Foundation

        @main
        struct \(name): AsyncParsableCommand {
            static var configuration = CommandConfiguration(
                commandName: "\(name.lowercased())",
                abstract: "A command-line tool created with SwiftCoderMCP",
                version: "1.0.0"
        """

        if !subcommands.isEmpty {
            mainContent += ",
        subcommands: ["
            let subcommandNames = subcommands.compactMap { $0["name"] as? String }
            mainContent += subcommandNames.map { "\($0).self" }.joined(separator: ", ")
            mainContent += "]"
        }

        mainContent += "
    )"

        // Add main arguments
        for arg in arguments {
            if let argName = arg["name"] as? String,
               let argType = arg["type"] as? String {
                let help = arg["help"] as? String ?? ""
                let shortName = arg["shortName"] as? String
                let defaultValue = arg["defaultValue"]

                mainContent += "
    "
                if let short = shortName {
                    mainContent += "@Option(name: .shortAndLong, help: "\(help)")
    "
                } else {
                    mainContent += "@Option(help: "\(help)")
    "
                }

                if let defaultVal = defaultValue {
                    mainContent += "var \(argName): \(argType) = \(defaultVal)"
                } else {
                    mainContent += "var \(argName): \(argType)?"
                }
            }
        }

        // Add flags
        for flag in flags {
            if let flagName = flag["name"] as? String {
                let help = flag["help"] as? String ?? ""
                let shortName = flag["shortName"] as? String

                mainContent += "
    "
                if let short = shortName {
                    mainContent += "@Flag(name: .shortAndLong, help: "\(help)")
    "
                } else {
                    mainContent += "@Flag(help: "\(help)")
    "
                }
                mainContent += "var \(flagName) = false"
            }
        }

        mainContent += """


            mutating func run() async throws {
                // Main command implementation
                print("Running \(name)...")
        """

        for arg in arguments {
            if let argName = arg["name"] as? String {
                mainContent += "
        if let \(argName) = \(argName) {
            print("\(argName): \\(\(argName))")
        }"
            }
        }

        for flag in flags {
            if let flagName = flag["name"] as? String {
                mainContent += "
        if \(flagName) {
            print("\(flagName) flag is set")
        }"
            }
        }

        mainContent += "
    }
}
"

        // Add subcommand implementations
        for subcommand in subcommands {
            guard let subName = subcommand["name"] as? String,
                  let subDesc = subcommand["description"] as? String else { continue }

            mainContent += """

            struct \(subName): AsyncParsableCommand {
                static var configuration = CommandConfiguration(
                    commandName: "\(subName.lowercased())",
                    abstract: "\(subDesc)"
                )

                func run() async throws {
                    print("Running \(subName) subcommand...")
                }
            }
            """
        }

        let mainPath = sourcesPath.appendingPathComponent("main.swift")
        try mainContent.write(to: mainPath, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "toolName": name,
            "path": toolPath.path,
            "arguments": arguments.count,
            "flags": flags.count,
            "subcommands": subcommands.count,
            "filesCreated": ["Package.swift", "Sources/\(name)/main.swift"]
        ]
    }

    private func createAutomationScript(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String,
              let path = args["path"] as? String,
              let automationType = args["automationType"] as? String else {
            throw MCPError.invalidParams
        }

        let actions = args["actions"] as? [String] ?? []

        let scriptPath = URL(fileURLWithPath: path).appendingPathComponent("\(name)Automation.swift")

        var scriptContent = """
        #!/usr/bin/env swift

        import Foundation
        import Cocoa

        // MARK: - \(name) Automation

        """

        switch automationType {
        case "file":
            scriptContent += """
            // File automation
            let fileManager = FileManager.default
            let workspace = NSWorkspace.shared

            """
            for action in actions {
                scriptContent += "// Action: \(action)
"
            }

        case "app":
            scriptContent += """
            // Application automation
            let workspace = NSWorkspace.shared
            let runningApps = workspace.runningApplications

            """
            for action in actions {
                scriptContent += "// Action: \(action)
"
            }

        case "system":
            scriptContent += """
            // System automation
            let process = Process()
            let pipe = Pipe()

            """
            for action in actions {
                scriptContent += "// Action: \(action)
"
            }

        case "clipboard":
            scriptContent += """
            // Clipboard automation
            let pasteboard = NSPasteboard.general

            """
            for action in actions {
                scriptContent += "// Action: \(action)
"
            }

        default:
            scriptContent += "// Generic automation
"
        }

        scriptContent += """

        // MARK: - Main

        print("\u{001B}[36mRunning \(name) automation...\u{001B}[0m")

        // Execute automation logic

        print("\u{001B}[32mAutomation complete!\u{001B}[0m")
        """

        try scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)

        // Make executable
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/chmod")
        process.arguments = ["+x", scriptPath.path]
        try process.run()
        process.waitUntilExit()

        return [
            "success": true,
            "scriptPath": scriptPath.path,
            "automationType": automationType,
            "actions": actions.count
        ]
    }

    private func bundleScript(_ args: [String: Any]) async throws -> Any {
        guard let scriptPath = args["scriptPath"] as? String,
              let outputPath = args["outputPath"] as? String else {
            throw MCPError.invalidParams
        }

        let includeDependencies = args["includeDependencies"] as? Bool ?? true
        let stripSymbols = args["stripSymbols"] as? Bool ?? false

        // Create temporary package structure
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Read original script
        let scriptURL = URL(fileURLWithPath: scriptPath)
        let scriptContent = try String(contentsOf: scriptURL, encoding: .utf8)

        // Create Package.swift
        let packageSwift = """
        // swift-tools-version: 5.9
        import PackageDescription

        let package = Package(
            name: "BundledScript",
            platforms: [.macOS(.v13)],
            targets: [
                .executableTarget(name: "BundledScript"),
            ]
        )
        """

        try packageSwift.write(to: tempDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

        // Create source
        let sourcesDir = tempDir.appendingPathComponent("Sources/BundledScript")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)

        // Remove shebang if present
        var sourceContent = scriptContent
        if sourceContent.hasPrefix("#!/") {
            if let newlineIndex = sourceContent.firstIndex(of: "
") {
                sourceContent.removeSubrange(sourceContent.startIndex...newlineIndex)
            }
        }

        try sourceContent.write(to: sourcesDir.appendingPathComponent("main.swift"), atomically: true, encoding: .utf8)

        // Build
        var buildCommand = "cd \(tempDir.path) && swift build -c release"
        if stripSymbols {
            buildCommand += " -Xswiftc -strip-all"
        }

        let result = try await runCommand(buildCommand)

        if result.exitCode == 0 {
            // Copy to output
            let builtBinary = tempDir.appendingPathComponent(".build/release/BundledScript")
            let outputURL = URL(fileURLWithPath: outputPath)
            try FileManager.default.copyItem(at: builtBinary, to: outputURL)

            // Cleanup
            try? FileManager.default.removeItem(at: tempDir)

            return [
                "success": true,
                "outputPath": outputPath,
                "originalScript": scriptPath,
                "isStandalone": true,
                "dependenciesIncluded": includeDependencies
            ]
        } else {
            return [
                "success": false,
                "error": result.output,
                "buildCommand": buildCommand
            ]
        }
    }

    private func runCommand(_ command: String) async throws -> (output: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        return (output, process.terminationStatus)
    }
}
