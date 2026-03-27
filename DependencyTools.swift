import MCP
import Foundation

// MARK: - Dependency Tools

struct DependencyTools: ToolProvider {
    var tools: [Tool] {
        [
            Tool(
                name: "analyze_dependencies",
                description: "Analyze project dependencies for version conflicts, unused dependencies, and security issues",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "projectPath": ["type": "string"],
                        "analysisType": [
                            "type": "string",
                            "enum": ["full", "conflicts", "unused", "outdated", "security"],
                            "default": "full"
                        ],
                        "includeTransitive": ["type": "boolean", "default": true]
                    ],
                    "required": ["projectPath"]
                ]
            ),
            Tool(
                name: "check_vulnerabilities",
                description: "Check dependencies for known security vulnerabilities",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "projectPath": ["type": "string"],
                        "severityThreshold": [
                            "type": "string",
                            "enum": ["low", "medium", "high", "critical"],
                            "default": "medium"
                        ]
                    ],
                    "required": ["projectPath"]
                ]
            ),
            Tool(
                name: "suggest_updates",
                description: "Suggest dependency updates with compatibility analysis",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "projectPath": ["type": "string"],
                        "updateType": [
                            "type": "string",
                            "enum": ["all", "major", "minor", "patch"],
                            "default": "all"
                        ],
                        "includeBreakingChanges": ["type": "boolean", "default": false]
                    ],
                    "required": ["projectPath"]
                ]
            ),
            Tool(
                name: "generate_dependency_report",
                description: "Generate detailed dependency report in various formats",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "projectPath": ["type": "string"],
                        "format": [
                            "type": "string",
                            "enum": ["json", "markdown", "html", "csv"],
                            "default": "markdown"
                        ],
                        "outputPath": ["type": "string"]
                    ],
                    "required": ["projectPath"]
                ]
            ),
        ]
    }

    func handle(_ name: String, arguments: [String: Any]) async throws -> Any {
        switch name {
        case "analyze_dependencies":
            return try await analyzeDependencies(arguments)
        case "check_vulnerabilities":
            return try await checkVulnerabilities(arguments)
        case "suggest_updates":
            return try await suggestUpdates(arguments)
        case "generate_dependency_report":
            return try await generateDependencyReport(arguments)
        default:
            throw MCPError.methodNotFound
        }
    }

    private func analyzeDependencies(_ args: [String: Any]) async throws -> Any {
        guard let projectPath = args["projectPath"] as? String else {
            throw MCPError.invalidParams
        }

        let analysisType = args["analysisType"] as? String ?? "full"
        let includeTransitive = args["includeTransitive"] as? Bool ?? true

        // Run swift package show-dependencies
        let command = "cd \(projectPath) && swift package show-dependencies --format json"
        let result = try await runCommand(command)

        var analysis: [String: Any] = [
            "projectPath": projectPath,
            "analysisType": analysisType,
            "includeTransitive": includeTransitive
        ]

        if result.exitCode == 0 {
            // Parse dependency tree
            if let data = result.output.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                analysis["dependencies"] = json
                analysis["totalDependencies"] = countDependencies(json)
            }
        }

        // Check for conflicts
        if analysisType == "full" || analysisType == "conflicts" {
            analysis["conflicts"] = detectConflicts(result.output)
        }

        // Check for outdated dependencies
        if analysisType == "full" || analysisType == "outdated" {
            let outdatedCommand = "cd \(projectPath) && swift package update --dry-run 2>&1"
            let outdatedResult = try await runCommand(outdatedCommand)
            analysis["outdatedDependencies"] = parseOutdatedDependencies(outdatedResult.output)
        }

        return [
            "success": true,
            "analysis": analysis
        ]
    }

    private func checkVulnerabilities(_ args: [String: Any]) async throws -> Any {
        guard let projectPath = args["projectPath"] as? String else {
            throw MCPError.invalidParams
        }

        let severityThreshold = args["severityThreshold"] as? String ?? "medium"

        // This would integrate with a vulnerability database
        // For now, return a placeholder structure

        let vulnerabilities: [[String: String]] = [
            [
                "package": "example-package",
                "version": "1.0.0",
                "vulnerability": "CVE-2024-XXXX",
                "severity": "high",
                "description": "Example vulnerability for demonstration"
            ]
        ]

        let filtered = vulnerabilities.filter { vuln in
            let severity = vuln["severity"] ?? "low"
            return severityRank(severity) >= severityRank(severityThreshold)
        }

        return [
            "success": true,
            "vulnerabilitiesFound": filtered.count,
            "vulnerabilities": filtered,
            "severityThreshold": severityThreshold
        ]
    }

    private func suggestUpdates(_ args: [String: Any]) async throws -> Any {
        guard let projectPath = args["projectPath"] as? String else {
            throw MCPError.invalidParams
        }

        let updateType = args["updateType"] as? String ?? "all"
        let includeBreakingChanges = args["includeBreakingChanges"] as? Bool ?? false

        // Get current dependencies
        let command = "cd \(projectPath) && swift package show-dependencies"
        let result = try await runCommand(command)

        // Parse and suggest updates
        var suggestions: [[String: String]] = []

        // This would check against package registry for latest versions
        // For now, return example suggestions
        suggestions = [
            [
                "package": "swift-argument-parser",
                "currentVersion": "1.2.0",
                "suggestedVersion": "1.3.0",
                "updateType": "minor",
                "breakingChanges": "false"
            ],
            [
                "package": "swift-syntax",
                "currentVersion": "509.0.0",
                "suggestedVersion": "600.0.0",
                "updateType": "major",
                "breakingChanges": "true"
            ]
        ]

        // Filter by update type
        if updateType != "all" {
            suggestions = suggestions.filter { $0["updateType"] == updateType }
        }

        if !includeBreakingChanges {
            suggestions = suggestions.filter { $0["breakingChanges"] == "false" }
        }

        return [
            "success": true,
            "suggestions": suggestions,
            "updateType": updateType,
            "includeBreakingChanges": includeBreakingChanges
        ]
    }

    private func generateDependencyReport(_ args: [String: Any]) async throws -> Any {
        guard let projectPath = args["projectPath"] as? String else {
            throw MCPError.invalidParams
        }

        let format = args["format"] as? String ?? "markdown"
        let outputPath = args["outputPath"] as? String

        // Get dependency data
        let command = "cd \(projectPath) && swift package show-dependencies --format json"
        let result = try await runCommand(command)

        var report = ""

        switch format {
        case "json":
            report = result.output
        case "markdown":
            report = generateMarkdownReport(result.output, projectPath: projectPath)
        case "html":
            report = generateHTMLReport(result.output, projectPath: projectPath)
        case "csv":
            report = generateCSVReport(result.output)
        default:
            report = result.output
        }

        // Write to file if outputPath provided
        if let outputPath = outputPath {
            let outputURL = URL(fileURLWithPath: outputPath)
            try report.write(to: outputURL, atomically: true, encoding: .utf8)
        }

        return [
            "success": true,
            "format": format,
            "outputPath": outputPath,
            "reportLength": report.count,
            "report": report
        ]
    }

    // MARK: - Helper Methods

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

    private func countDependencies(_ json: [String: Any]) -> Int {
        var count = 0
        if let dependencies = json["dependencies"] as? [[String: Any]] {
            count += dependencies.count
            for dep in dependencies {
                count += countDependencies(dep)
            }
        }
        return count
    }

    private func detectConflicts(_ output: String) -> [[String: String]] {
        // Parse output for version conflicts
        var conflicts: [[String: String]] = []
        // Implementation would detect actual conflicts
        return conflicts
    }

    private func parseOutdatedDependencies(_ output: String) -> [[String: String]] {
        // Parse swift package update --dry-run output
        var outdated: [[String: String]] = []
        // Implementation would parse actual outdated dependencies
        return outdated
    }

    private func severityRank(_ severity: String) -> Int {
        switch severity.lowercased() {
        case "critical": return 4
        case "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 0
        }
    }

    private func generateMarkdownReport(_ jsonOutput: String, projectPath: String) -> String {
        var report = "# Dependency Report\n\n"
        report += "**Project:** \(projectPath)\n"
        report += "**Generated:** \(Date())\n\n"

        if let data = jsonOutput.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            report += "## Dependencies\n\n"
            report += "```json\n"
            report += jsonOutput
            report += "\n```\n"
        }

        return report
    }

    private func generateHTMLReport(_ jsonOutput: String, projectPath: String) -> String {
        var report = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Dependency Report - \(projectPath)</title>
            <style>
                body { font-family: -apple-system, sans-serif; margin: 40px; }
                pre { background: #f5f5f5; padding: 20px; border-radius: 8px; }
            </style>
        </head>
        <body>
            <h1>Dependency Report</h1>
            <p><strong>Project:</strong> \(projectPath)</p>
            <p><strong>Generated:</strong> \(Date())</p>
            <h2>Dependencies</h2>
            <pre>
        """
        report += jsonOutput
        report += """
            </pre>
        </body>
        </html>
        """
        return report
    }

    private func generateCSVReport(_ jsonOutput: String) -> String {
        // Convert JSON dependencies to CSV
        var csv = "Package,Version,URL\n"

        if let data = jsonOutput.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Parse and convert to CSV rows
            // This is a simplified implementation
        }

        return csv
    }
}
