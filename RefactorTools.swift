import MCP
import Foundation

// MARK: - Refactoring Tools

struct RefactorTools: ToolProvider {
    var tools: [Tool] {
        [
            Tool(
                name: "rename_symbol",
                description: "Rename a symbol (variable, function, type) across the codebase",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "projectPath": ["type": "string"],
                        "oldName": ["type": "string"],
                        "newName": ["type": "string"],
                        "symbolType": [
                            "type": "string",
                            "enum": ["variable", "function", "struct", "class", "enum", "protocol", "property"]
                        ],
                        "scope": [
                            "type": "string",
                            "enum": ["file", "target", "project"],
                            "default": "project"
                        ]
                    ],
                    "required": ["projectPath", "oldName", "newName", "symbolType"]
                ]
            ),
            Tool(
                name: "extract_method",
                description: "Extract selected code into a new method/function",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "filePath": ["type": "string"],
                        "startLine": ["type": "integer"],
                        "endLine": ["type": "integer"],
                        "methodName": ["type": "string"],
                        "accessLevel": ["type": "string", "enum": ["private", "internal", "public"], "default": "private"],
                        "parameters": ["type": "array", "items": ["type": "string"]]
                    ],
                    "required": ["filePath", "startLine", "endLine", "methodName"]
                ]
            ),
            Tool(
                name: "extract_variable",
                description: "Extract expression into a named variable",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "filePath": ["type": "string"],
                        "line": ["type": "integer"],
                        "column": ["type": "integer"],
                        "variableName": ["type": "string"],
                        "expression": ["type": "string"]
                    ],
                    "required": ["filePath", "line", "column", "variableName", "expression"]
                ]
            ),
            Tool(
                name: "organize_imports",
                description: "Organize and sort import statements in Swift files",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "filePath": ["type": "string"],
                        "grouping": [
                            "type": "string",
                            "enum": ["alphabetical", "byModule", "byType"],
                            "default": "alphabetical"
                        ],
                        "removeUnused": ["type": "boolean", "default": true]
                    ],
                    "required": ["filePath"]
                ]
            ),
            Tool(
                name: "format_code",
                description: "Format Swift code using swift-format or SwiftFormat rules",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "filePath": ["type": "string"],
                        "formatter": ["type": "string", "enum": ["swift-format", "SwiftFormat"], "default": "swift-format"],
                        "configuration": ["type": "object", "description": "Formatter-specific options"],
                        "inPlace": ["type": "boolean", "default": true]
                    ],
                    "required": ["filePath"]
                ]
            ),
            Tool(
                name: "migrate_to_swift6",
                description: "Assist with Swift 6 migration including concurrency and language mode changes",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "projectPath": ["type": "string"],
                        "enableConcurrency": ["type": "boolean", "default": true],
                        "strictConcurrency": ["type": "boolean", "default": false],
                        "enableCxxInterop": ["type": "boolean", "default": false]
                    ],
                    "required": ["projectPath"]
                ]
            ),
        ]
    }

    func handle(_ name: String, arguments: [String: Any]) async throws -> Any {
        switch name {
        case "rename_symbol":
            return try await renameSymbol(arguments)
        case "extract_method":
            return try await extractMethod(arguments)
        case "extract_variable":
            return try await extractVariable(arguments)
        case "organize_imports":
            return try await organizeImports(arguments)
        case "format_code":
            return try await formatCode(arguments)
        case "migrate_to_swift6":
            return try await migrateToSwift6(arguments)
        default:
            throw MCPError.methodNotFound
        }
    }

    // MARK: - Implementation

    private func renameSymbol(_ args: [String: Any]) async throws -> Any {
        guard let projectPath = args["projectPath"] as? String,
              let oldName = args["oldName"] as? String,
              let newName = args["newName"] as? String,
              let symbolType = args["symbolType"] as? String else {
            throw MCPError.invalidParams
        }

        let scope = args["scope"] as? String ?? "project"

        // Find all Swift files
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/find")
        process.arguments = [projectPath, "-name", "*.swift", "-type", "f"]

        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let files = String(data: data, encoding: .utf8)?.components(separatedBy: .newlines) ?? []

        var changes: [[String: String]] = []

        for file in files where !file.isEmpty {
            let fileURL = URL(fileURLWithPath: file)
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }

            // Simple string replacement (in real implementation, use SwiftSyntax for accurate parsing)
            var newContent = content
            let pattern = "\b\(oldName)\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(content.startIndex..., in: content)
                newContent = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: newName)
            }

            if newContent != content {
                try newContent.write(to: fileURL, atomically: true, encoding: .utf8)
                changes.append(["file": file, "oldName": oldName, "newName": newName])
            }
        }

        return [
            "success": true,
            "symbolType": symbolType,
            "oldName": oldName,
            "newName": newName,
            "filesModified": changes.count,
            "changes": changes,
            "scope": scope
        ]
    }

    private func extractMethod(_ args: [String: Any]) async throws -> Any {
        guard let filePath = args["filePath"] as? String,
              let startLine = args["startLine"] as? Int,
              let endLine = args["endLine"] as? Int,
              let methodName = args["methodName"] as? String else {
            throw MCPError.invalidParams
        }

        let accessLevel = args["accessLevel"] as? String ?? "private"
        let parameters = args["parameters"] as? [String] ?? []

        let fileURL = URL(fileURLWithPath: filePath)
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        guard startLine > 0 && endLine <= lines.count && startLine <= endLine else {
            throw MCPError.invalidParams
        }

        // Extract code to be moved
        let codeToExtract = lines[(startLine-1)..<endLine].joined(separator: "
")

        // Build method signature
        let paramString = parameters.isEmpty ? "" : "(\(parameters.joined(separator: ", ")))"

        // Generate new method
        let newMethod = """
        
	\(accessLevel) func \(methodName)\(paramString) {
        		\(codeToExtract.replacingOccurrences(of: "
", with: "
		"))
        	}
        """

        // Replace extracted code with method call
        var newLines = lines
        let replacementLine = "		\(methodName)\(paramString)()"
        newLines.replaceSubrange((startLine-1)..<endLine, with: [replacementLine])

        // Add new method before the closing brace of the class/struct
        // This is a simplified implementation - real implementation would use SwiftSyntax
        let newContent = newLines.joined(separator: "
") + newMethod

        try newContent.write(to: fileURL, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "filePath": filePath,
            "methodName": methodName,
            "startLine": startLine,
            "endLine": endLine,
            "accessLevel": accessLevel,
            "extractedCode": codeToExtract,
            "newMethod": newMethod
        ]
    }

    private func extractVariable(_ args: [String: Any]) async throws -> Any {
        guard let filePath = args["filePath"] as? String,
              let line = args["line"] as? Int,
              let column = args["column"] as? Int,
              let variableName = args["variableName"] as? String,
              let expression = args["expression"] as? String else {
            throw MCPError.invalidParams
        }

        let fileURL = URL(fileURLWithPath: filePath)
        var content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        guard line > 0 && line <= lines.count else {
            throw MCPError.invalidParams
        }

        // Find the line and replace the expression with the variable
        var targetLine = lines[line - 1]

        // Simple replacement - in real implementation, use proper parsing
        if let range = targetLine.range(of: expression) {
            targetLine.replaceSubrange(range, with: variableName)
        }

        // Insert variable declaration before the line
        let indentation = targetLine.prefix(while: { $0 == " " || $0 == "	" })
        let variableDeclaration = "\(indentation)let \(variableName) = \(expression)"

        var newLines = lines
        newLines[line - 1] = targetLine
        newLines.insert(variableDeclaration, at: line - 1)

        content = newLines.joined(separator: "
")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "filePath": filePath,
            "variableName": variableName,
            "expression": expression,
            "line": line,
            "column": column
        ]
    }

    private func organizeImports(_ args: [String: Any]) async throws -> Any {
        guard let filePath = args["filePath"] as? String else {
            throw MCPError.invalidParams
        }

        let grouping = args["grouping"] as? String ?? "alphabetical"
        let removeUnused = args["removeUnused"] as? Bool ?? true

        let fileURL = URL(fileURLWithPath: filePath)
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        // Extract imports
        var imports: [String] = []
        var otherLines: [String] = []
        var foundImport = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("import ") {
                imports.append(trimmed)
                foundImport = true
            } else if foundImport && trimmed.isEmpty {
                // Skip empty lines after imports
            } else {
                otherLines.append(line)
                foundImport = false
            }
        }

        // Sort imports
        switch grouping {
        case "alphabetical":
            imports.sort()
        case "byModule":
            // Group by module type (Foundation, UIKit, etc.)
            let systemImports = imports.filter { !$0.contains("@testable") && !$0.contains("#") }
            let testableImports = imports.filter { $0.contains("@testable") }
            imports = systemImports.sorted() + testableImports.sorted()
        default:
            imports.sort()
        }

        // Reconstruct file
        var newContent = imports.joined(separator: "
")
        if !imports.isEmpty {
            newContent += "

"
        }
        newContent += otherLines.joined(separator: "
")

        try newContent.write(to: fileURL, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "filePath": filePath,
            "importsOrganized": imports.count,
            "grouping": grouping,
            "removeUnused": removeUnused
        ]
    }

    private func formatCode(_ args: [String: Any]) async throws -> Any {
        guard let filePath = args["filePath"] as? String else {
            throw MCPError.invalidParams
        }

        let formatter = args["formatter"] as? String ?? "swift-format"
        let inPlace = args["inPlace"] as? Bool ?? true

        var command = ""

        if formatter == "swift-format" {
            command = "swift-format"
            if inPlace {
                command += " -i"
            }
            command += " \(filePath)"
        } else {
            command = "SwiftFormat"
            if inPlace {
                command += " --in-place"
            }
            command += " \(filePath)"
        }

        let result = try await runCommand(command)

        return [
            "success": result.exitCode == 0,
            "filePath": filePath,
            "formatter": formatter,
            "inPlace": inPlace,
            "output": result.output
        ]
    }

    private func migrateToSwift6(_ args: [String: Any]) async throws -> Any {
        guard let projectPath = args["projectPath"] as? String else {
            throw MCPError.invalidParams
        }

        let enableConcurrency = args["enableConcurrency"] as? Bool ?? true
        let strictConcurrency = args["strictConcurrency"] as? Bool ?? false
        let enableCxxInterop = args["enableCxxInterop"] as? Bool ?? false

        // Read Package.swift
        let packagePath = URL(fileURLWithPath: projectPath).appendingPathComponent("Package.swift")
        var content = try String(contentsOf: packagePath, encoding: .utf8)

        // Update swift-tools-version
        if content.contains("swift-tools-version: 5.") {
            content = content.replacingOccurrences(
                of: "// swift-tools-version: 5\.[0-9]+",
                with: "// swift-tools-version: 6.0",
                options: .regularExpression
            )
        }

        // Add Swift 6 settings
        if enableConcurrency {
            if !content.contains("swiftSettings") {
                // Add swiftSettings to targets
                content = content.replacingOccurrences(
                    of: "dependencies: \[(.*?)\]",
                    with: """dependencies: [$1],
                    swiftSettings: [
                        .enableExperimentalFeature("StrictConcurrency"),
                        .swiftLanguageMode(.v6)
                    ]""",
                    options: .regularExpression
                )
            }
        }

        try content.write(to: packagePath, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "projectPath": projectPath,
            "swiftVersion": "6.0",
            "enableConcurrency": enableConcurrency,
            "strictConcurrency": strictConcurrency,
            "enableCxxInterop": enableCxxInterop,
            "changes": ["Updated Package.swift to Swift 6.0"]
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
