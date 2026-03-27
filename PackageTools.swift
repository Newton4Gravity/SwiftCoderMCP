import MCP
import Foundation

// MARK: - Package Management Tools

struct PackageTools: ToolProvider {
    var tools: [Tool] {
        [
            Tool(
                name: "add_dependency",
                description: "Add a package dependency to Package.swift",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "url": ["type": "string"],
                        "version": ["type": "string"],
                        "products": ["type": "array", "items": ["type": "string"]],
                        "targets": ["type": "array", "items": ["type": "string"]],
                        "exactVersion": ["type": "boolean"],
                        "branch": ["type": "string"],
                        "revision": ["type": "string"]
                    ],
                    "required": ["packagePath", "url", "version"]
                ]
            ),
            Tool(
                name: "remove_dependency",
                description: "Remove a package dependency from Package.swift",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "dependencyName": ["type": "string"]
                    ],
                    "required": ["packagePath", "dependencyName"]
                ]
            ),
            Tool(
                name: "update_dependencies",
                description: "Update package dependencies to latest compatible versions",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "specificPackage": ["type": "string"],
                        "reset": ["type": "boolean"]
                    ]
                ]
            ),
            Tool(
                name: "resolve_dependencies",
                description: "Resolve package dependencies without updating",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"]
                    ]
                ]
            ),
            Tool(
                name: "show_dependencies",
                description: "Display dependency tree with versions",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "format": ["type": "string", "enum": ["text", "json", "dot"]]
                    ]
                ]
            ),
            Tool(
                name: "edit_package",
                description: "Edit Package.swift with new platforms, products, or settings",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "platforms": ["type": "array", "items": ["type": "string"]],
                        "swiftLanguageVersions": ["type": "array", "items": ["type": "string"]],
                        "products": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "type": ["enum": ["library", "executable"]],
                                    "targets": ["type": "array", "items": ["type": "string"]]
                                ]
                            ]
                        ]
                    ],
                    "required": ["packagePath"]
                ]
            ),
            Tool(
                name: "clean_package",
                description: "Clean package build artifacts and caches",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "purgeCache": ["type": "boolean"],
                        "reset": ["type": "boolean"]
                    ]
                ]
            ),
        ]
    }

    func handle(_ name: String, arguments: [String: Any]) async throws -> Any {
        switch name {
        case "add_dependency":
            return try await addDependency(arguments)
        case "remove_dependency":
            return try await removeDependency(arguments)
        case "update_dependencies":
            return try await updateDependencies(arguments)
        case "resolve_dependencies":
            return try await resolveDependencies(arguments)
        case "show_dependencies":
            return try await showDependencies(arguments)
        case "edit_package":
            return try await editPackage(arguments)
        case "clean_package":
            return try await cleanPackage(arguments)
        default:
            throw MCPError.methodNotFound
        }
    }

    // MARK: - Implementation

    private func addDependency(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String,
              let url = args["url"] as? String,
              let version = args["version"] as? String else {
            throw MCPError.invalidParams
        }

        let packageURL = URL(fileURLWithPath: packagePath).appendingPathComponent("Package.swift")
        let content = try String(contentsOf: packageURL, encoding: .utf8)

        var newContent = content

        // Extract package name from URL
        let packageName = url.components(separatedBy: "/").last?.replacingOccurrences(of: ".git", with: "") ?? "Dependency"

        // Add to dependencies array
        let dependencyLine: String
        if let branch = args["branch"] as? String {
            dependencyLine = ".package(url: "\(url)", branch: "\(branch)")"
        } else if let revision = args["revision"] as? String {
            dependencyLine = ".package(url: "\(url)", revision: "\(revision)")"
        } else if args["exactVersion"] as? Bool == true {
            dependencyLine = ".package(url: "\(url)", exact: "\(version)")"
        } else {
            dependencyLine = ".package(url: "\(url)", from: "\(version)")"
        }

        // Find dependencies section and insert
        if let range = newContent.range(of: "dependencies: [") {
            let insertIndex = newContent.index(range.upperBound, offsetBy: 0)
            newContent.insert(contentsOf: "
        \(dependencyLine),", at: insertIndex)
        }

        // Add to targets
        let targets = args["targets"] as? [String] ?? [packageName]
        let products = args["products"] as? [String] ?? [packageName]

        for target in targets {
            if let targetRange = newContent.range(of: "name: "\(target)"") {
                // Find the dependencies array for this target
                if let depRange = newContent.range(of: "dependencies: [", range: targetRange.upperBound..<newContent.endIndex) {
                    let insertIndex = newContent.index(depRange.upperBound, offsetBy: 0)
                    let productDeps = products.map { ".product(name: "\($0)", package: "\(packageName)")" }.joined(separator: ", ")
                    newContent.insert(contentsOf: "
                \(productDeps),", at: insertIndex)
                }
            }
        }

        try newContent.write(to: packageURL, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "message": "Added dependency \(packageName) to Package.swift",
            "dependency": packageName,
            "version": version
        ]
    }

    private func removeDependency(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String,
              let dependencyName = args["dependencyName"] as? String else {
            throw MCPError.invalidParams
        }

        let packageURL = URL(fileURLWithPath: packagePath).appendingPathComponent("Package.swift")
        var content = try String(contentsOf: packageURL, encoding: .utf8)

        // Remove from dependencies
        let patterns = [
            ".package(url: "[^"]*\(dependencyName)[^"]*"[^)]*),?",
            ".package(path: "[^"]*\(dependencyName)[^"]*"[^)]*),?"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(content.startIndex..., in: content)
                content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: "")
            }
        }

        // Remove from target dependencies
        let targetDepPattern = ".product(name: "[^"]*", package: "\(dependencyName)"),?"
        if let regex = try? NSRegularExpression(pattern: targetDepPattern, options: []) {
            let range = NSRange(content.startIndex..., in: content)
            content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: "")
        }

        try content.write(to: packageURL, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "message": "Removed dependency \(dependencyName)"
        ]
    }

    private func updateDependencies(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String else {
            throw MCPError.invalidParams
        }

        let specificPackage = args["specificPackage"] as? String
        let reset = args["reset"] as? Bool ?? false

        var command = "cd \(packagePath) && swift package"

        if reset {
            command += " reset && swift package resolve"
        } else if let pkg = specificPackage {
            command += " update \(pkg)"
        } else {
            command += " update"
        }

        let result = try await runCommand(command)

        return [
            "success": result.exitCode == 0,
            "output": result.output,
            "command": command
        ]
    }

    private func resolveDependencies(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String else {
            throw MCPError.invalidParams
        }

        let command = "cd \(packagePath) && swift package resolve"
        let result = try await runCommand(command)

        return [
            "success": result.exitCode == 0,
            "output": result.output
        ]
    }

    private func showDependencies(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String else {
            throw MCPError.invalidParams
        }

        let format = args["format"] as? String ?? "text"
        let command = "cd \(packagePath) && swift package show-dependencies --format \(format)"

        let result = try await runCommand(command)

        return [
            "success": result.exitCode == 0,
            "dependencies": result.output,
            "format": format
        ]
    }

    private func editPackage(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String else {
            throw MCPError.invalidParams
        }

        let packageURL = URL(fileURLWithPath: packagePath).appendingPathComponent("Package.swift")
        var content = try String(contentsOf: packageURL, encoding: .utf8)

        // Update platforms
        if let platforms = args["platforms"] as? [String] {
            let platformString = platforms.joined(separator: ", ")
            if let range = content.range(of: "platforms: [") {
                // Replace existing platforms
                if let endRange = content.range(of: "],", range: range.upperBound..<content.endIndex) {
                    content.replaceSubrange(range.upperBound..<endRange.lowerBound, with: platformString)
                }
            } else {
                // Insert platforms after name
                if let nameRange = content.range(of: "name: "[^"]*"", options: .regularExpression) {
                    let insertIndex = content.index(nameRange.upperBound, offsetBy: 0)
                    content.insert(contentsOf: ",
    platforms: [\(platformString)]", at: insertIndex)
                }
            }
        }

        // Update Swift language versions
        if let versions = args["swiftLanguageVersions"] as? [String] {
            let versionString = versions.joined(separator: ", ")
            if content.contains("swiftLanguageVersions") {
                // Replace existing
            } else {
                // Add new
            }
        }

        try content.write(to: packageURL, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "message": "Updated Package.swift"
        ]
    }

    private func cleanPackage(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String else {
            throw MCPError.invalidParams
        }

        let purgeCache = args["purgeCache"] as? Bool ?? false
        let reset = args["reset"] as? Bool ?? false

        var commands = ["cd \(packagePath) && swift package clean"]

        if reset {
            commands.append("cd \(packagePath) && swift package reset")
        }

        if purgeCache {
            commands.append("swift package purge-cache")
        }

        var outputs: [String] = []
        for command in commands {
            let result = try await runCommand(command)
            outputs.append(result.output)
        }

        return [
            "success": true,
            "outputs": outputs,
            "actions": commands
        ]
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
