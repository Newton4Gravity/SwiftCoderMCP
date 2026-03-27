import MCP
import Foundation

// MARK: - Build Tools

struct BuildTools: ToolProvider {
    var tools: [Tool] {
        [
            Tool(
                name: "build_target",
                description: "Build Swift package target with specific configuration",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "target": ["type": "string"],
                        "configuration": ["type": "string", "enum": ["debug", "release"], "default": "debug"],
                        "destination": ["type": "string", "description": "Build destination (e.g., 'platform=macOS')"],
                        "verbose": ["type": "boolean", "default": false],
                        "jobs": ["type": "integer", "description": "Number of parallel jobs"],
                        "buildTests": ["type": "boolean", "default": false]
                    ],
                    "required": ["packagePath"]
                ]
            ),
            Tool(
                name: "run_executable",
                description: "Build and run Swift executable with arguments",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "executable": ["type": "string"],
                        "arguments": ["type": "array", "items": ["type": "string"]],
                        "environment": ["type": "object"],
                        "configuration": ["type": "string", "enum": ["debug", "release"], "default": "debug"]
                    ],
                    "required": ["packagePath", "executable"]
                ]
            ),
            Tool(
                name: "test_package",
                description: "Run tests for Swift package with filtering and coverage",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "filter": ["type": "string", "description": "Test filter pattern"],
                        "parallel": ["type": "boolean", "default": true],
                        "enableCodeCoverage": ["type": "boolean", "default": false],
                        "configuration": ["type": "string", "enum": ["debug", "release"], "default": "debug"],
                        "testProduct": ["type": "string"]
                    ],
                    "required": ["packagePath"]
                ]
            ),
            Tool(
                name: "archive_build",
                description: "Create archive for distribution (XCFramework, executable, etc.)",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "outputPath": ["type": "string"],
                        "type": ["type": "string", "enum": ["xcframework", "executable", "library"]],
                        "targets": ["type": "array", "items": ["type": "string"]],
                        "platforms": ["type": "array", "items": ["type": "string"]]
                    ],
                    "required": ["packagePath", "outputPath", "type"]
                ]
            ),
            Tool(
                name: "benchmark_build",
                description: "Run performance benchmarks and analyze build times",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "iterations": ["type": "integer", "default": 3],
                        "cleanBetween": ["type": "boolean", "default": true]
                    ],
                    "required": ["packagePath"]
                ]
            ),
            Tool(
                name: "check_compatibility",
                description: "Check API compatibility between versions",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "packagePath": ["type": "string"],
                        "baseline": ["type": "string"],
                        "current": ["type": "string"]
                    ],
                    "required": ["packagePath"]
                ]
            ),
        ]
    }

    func handle(_ name: String, arguments: [String: Any]) async throws -> Any {
        switch name {
        case "build_target":
            return try await buildTarget(arguments)
        case "run_executable":
            return try await runExecutable(arguments)
        case "test_package":
            return try await testPackage(arguments)
        case "archive_build":
            return try await archiveBuild(arguments)
        case "benchmark_build":
            return try await benchmarkBuild(arguments)
        case "check_compatibility":
            return try await checkCompatibility(arguments)
        default:
            throw MCPError.methodNotFound
        }
    }

    // MARK: - Implementation

    private func buildTarget(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String else {
            throw MCPError.invalidParams
        }

        let target = args["target"] as? String
        let configuration = args["configuration"] as? String ?? "debug"
        let destination = args["destination"] as? String
        let verbose = args["verbose"] as? Bool ?? false
        let jobs = args["jobs"] as? Int
        let buildTests = args["buildTests"] as? Bool ?? false

        var command = "cd \(packagePath) && swift build -c \(configuration)"

        if let target = target {
            command += " --target \(target)"
        }

        if let destination = destination {
            command += " --destination '\(destination)'"
        }

        if verbose {
            command += " --verbose"
        }

        if let jobs = jobs {
            command += " -j \(jobs)"
        }

        if buildTests {
            command += " --build-tests"
        }

        let result = try await runCommand(command)

        return [
            "success": result.exitCode == 0,
            "output": result.output,
            "command": command,
            "configuration": configuration
        ]
    }

    private func runExecutable(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String,
              let executable = args["executable"] as? String else {
            throw MCPError.invalidParams
        }

        let arguments = args["arguments"] as? [String] ?? []
        let environment = args["environment"] as? [String: String] ?? [:]
        let configuration = args["configuration"] as? String ?? "debug"

        var command = "cd \(packagePath) && swift run -c \(configuration) \(executable)"

        if !arguments.isEmpty {
            command += " \(arguments.joined(separator: " "))"
        }

        var envVars = ""
        for (key, value) in environment {
            envVars += "\(key)=\(value) "
        }

        if !envVars.isEmpty {
            command = envVars + command
        }

        let result = try await runCommand(command)

        return [
            "success": result.exitCode == 0,
            "output": result.output,
            "executable": executable,
            "arguments": arguments
        ]
    }

    private func testPackage(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String else {
            throw MCPError.invalidParams
        }

        let filter = args["filter"] as? String
        let parallel = args["parallel"] as? Bool ?? true
        let enableCodeCoverage = args["enableCodeCoverage"] as? Bool ?? false
        let configuration = args["configuration"] as? String ?? "debug"
        let testProduct = args["testProduct"] as? String

        var command = "cd \(packagePath) && swift test -c \(configuration)"

        if let filter = filter {
            command += " --filter \(filter)"
        }

        if !parallel {
            command += " --parallel=false"
        }

        if enableCodeCoverage {
            command += " --enable-code-coverage"
        }

        if let testProduct = testProduct {
            command += " --test-product \(testProduct)"
        }

        let result = try await runCommand(command)

        return [
            "success": result.exitCode == 0,
            "output": result.output,
            "testsPassed": result.exitCode == 0,
            "configuration": configuration
        ]
    }

    private func archiveBuild(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String,
              let outputPath = args["outputPath"] as? String,
              let type = args["type"] as? String else {
            throw MCPError.invalidParams
        }

        let targets = args["targets"] as? [String] ?? []
        let platforms = args["platforms"] as? [String] ?? []

        var command = "cd \(packagePath) && "

        switch type {
        case "xcframework":
            command += "xcodebuild -create-xcframework"
            for target in targets {
                let archivePath = "\(packagePath)/.build/archives/\(target).xcarchive"
                command += " -archive \(archivePath) -frameworks \(target).framework"
            }
            command += " -output \(outputPath)"

        case "executable":
            command += "swift build -c release && cp .build/release/\(targets.first ?? "executable") \(outputPath)"

        case "library":
            command += "swift build -c release && cp -r .build/release/*.a \(outputPath)"

        default:
            throw MCPError.invalidParams
        }

        let result = try await runCommand(command)

        return [
            "success": result.exitCode == 0,
            "output": result.output,
            "archiveType": type,
            "outputPath": outputPath
        ]
    }

    private func benchmarkBuild(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String else {
            throw MCPError.invalidParams
        }

        let iterations = args["iterations"] as? Int ?? 3
        let cleanBetween = args["cleanBetween"] as? Bool ?? true

        var times: [Double] = []
        var outputs: [String] = []

        for i in 0..<iterations {
            if cleanBetween {
                _ = try await runCommand("cd \(packagePath) && swift package clean")
            }

            let start = Date()
            let result = try await runCommand("cd \(packagePath) && swift build -c release")
            let end = Date()

            let duration = end.timeIntervalSince(start)
            times.append(duration)
            outputs.append("Iteration \(i+1): \(String(format: "%.2f", duration))s")

            if result.exitCode != 0 {
                return [
                    "success": false,
                    "error": "Build failed on iteration \(i+1)",
                    "output": result.output
                ]
            }
        }

        let avg = times.reduce(0, +) / Double(times.count)
        let min = times.min() ?? 0
        let max = times.max() ?? 0

        return [
            "success": true,
            "iterations": iterations,
            "averageTime": avg,
            "minTime": min,
            "maxTime": max,
            "details": outputs
        ]
    }

    private func checkCompatibility(_ args: [String: Any]) async throws -> Any {
        guard let packagePath = args["packagePath"] as? String else {
            throw MCPError.invalidParams
        }

        let baseline = args["baseline"] as? String ?? "HEAD~1"
        let current = args["current"] as? String ?? "HEAD"

        let command = "cd \(packagePath) && swift package diagnose-api-breaking-changes \(baseline) --against \(current)"
        let result = try await runCommand(command)

        return [
            "success": result.exitCode == 0,
            "output": result.output,
            "baseline": baseline,
            "current": current,
            "breakingChanges": result.exitCode != 0
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
