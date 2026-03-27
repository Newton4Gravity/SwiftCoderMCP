import MCP
import Foundation

// MARK: - Macro Tools

struct MacroTools: ToolProvider {
    var tools: [Tool] {
        [
            Tool(
                name: "create_macro_package",
                description: "Create complete Swift macro package with compiler plugin structure",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "path": ["type": "string"],
                        "macroTypes": [
                            "type": "array",
                            "items": [
                                "type": "string",
                                "enum": ["expression", "declaration", "accessor", "attached", "peer", "member"]
                            ],
                            "description": "Types of macros to include"
                        ],
                        "includeTests": ["type": "boolean", "default": true],
                        "swiftSyntaxVersion": ["type": "string", "default": "600.0.0"]
                    ],
                    "required": ["name", "path"]
                ]
            ),
            Tool(
                name: "generate_macro_expansion_test",
                description: "Generate test code for macro expansion using assertMacro or assertMacroExpansion",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "macroName": ["type": "string"],
                        "inputCode": ["type": "string"],
                        "expectedOutput": ["type": "string"],
                        "testFramework": ["type": "string", "enum": ["XCTest", "SwiftTesting"], "default": "SwiftTesting"],
                        "testLibrary": ["type": "string", "enum": ["Apple", "PointFreeCo"], "default": "PointFreeCo"]
                    ],
                    "required": ["macroName", "inputCode"]
                ]
            ),
            Tool(
                name: "debug_macro_expansion",
                description: "Generate debugging configuration for macro expansion issues",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "macroName": ["type": "string"],
                        "issue": ["type": "string", "description": "Description of the issue"],
                        "inputCode": ["type": "string"],
                        "errorMessage": ["type": "string"]
                    ],
                    "required": ["macroName", "issue"]
                ]
            ),
            Tool(
                name: "create_macro_diagnostic",
                description: "Generate diagnostic messages and fix-its for macros",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "macroName": ["type": "string"],
                        "diagnostics": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "id": ["type": "string"],
                                    "message": ["type": "string"],
                                    "severity": ["type": "string", "enum": ["error", "warning", "note"]],
                                    "fixItMessage": ["type": "string"],
                                    "replacementCode": ["type": "string"]
                                ]
                            ]
                        ]
                    ],
                    "required": ["macroName"]
                ]
            ),
            Tool(
                name: "analyze_swift_syntax",
                description: "Analyze Swift code using SwiftSyntax AST for macro development",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "code": ["type": "string"],
                        "analysisType": [
                            "type": "string",
                            "enum": ["structure", "identifiers", "types", "functions", "all"]
                        ]
                    ],
                    "required": ["code"]
                ]
            ),
        ]
    }

    func handle(_ name: String, arguments: [String: Any]) async throws -> Any {
        switch name {
        case "create_macro_package":
            return try await createMacroPackage(arguments)
        case "generate_macro_expansion_test":
            return try await generateMacroExpansionTest(arguments)
        case "debug_macro_expansion":
            return try await debugMacroExpansion(arguments)
        case "create_macro_diagnostic":
            return try await createMacroDiagnostic(arguments)
        case "analyze_swift_syntax":
            return try await analyzeSwiftSyntax(arguments)
        default:
            throw MCPError.methodNotFound
        }
    }

    // MARK: - Implementation

    private func createMacroPackage(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String,
              let path = args["path"] as? String else {
            throw MCPError.invalidParams
        }

        let macroTypes = args["macroTypes"] as? [String] ?? ["expression", "attached"]
        let includeTests = args["includeTests"] as? Bool ?? true
        let swiftSyntaxVersion = args["swiftSyntaxVersion"] as? String ?? "600.0.0"

        let packagePath = URL(fileURLWithPath: path).appendingPathComponent(name)

        // Create directory structure
        let directories = [
            "Sources/\(name)",
            "Sources/\(name)Macros",
            includeTests ? "Tests/\(name)Tests" : nil
        ].compactMap { $0 }

        for dir in directories {
            let dirPath = packagePath.appendingPathComponent(dir)
            try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)
        }

        // Generate Package.swift
        let packageSwift = """
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
                .package(url: "https://github.com/apple/swift-syntax.git", from: "\(swiftSyntaxVersion)"),
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
                \(includeTests ? """.testTarget(
                    name: "\(name)Tests",
                    dependencies: [
                        "\(name)Macros",
                        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                    ]
                ),""" : "")
            ]
        )
        """

        let packageSwiftPath = packagePath.appendingPathComponent("Package.swift")
        try packageSwift.write(to: packageSwiftPath, atomically: true, encoding: .utf8)

        // Generate macro declarations
        var macroDecls = ""
        for type in macroTypes {
            switch type {
            case "expression":
                macroDecls += """
                /// A freestanding expression macro
                @freestanding(expression)
                public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(
                    module: "\(name)Macros",
                    type: "StringifyMacro"
                )

                """
            case "declaration":
                macroDecls += """
                /// A freestanding declaration macro
                @freestanding(declaration, names: named(MyType))
                public macro declareType(_ name: String) = #externalMacro(
                    module: "\(name)Macros",
                    type: "DeclareTypeMacro"
                )

                """
            case "attached":
                macroDecls += """
                /// An attached member macro
                @attached(member, names: named(init))
                public macro AddInit() = #externalMacro(
                    module: "\(name)Macros",
                    type: "AddInitMacro"
                )

                """
            case "peer":
                macroDecls += """
                /// An attached peer macro
                @attached(peer, names: suffixed(Preview))
                public macro AddPreview() = #externalMacro(
                    module: "\(name)Macros",
                    type: "AddPreviewMacro"
                )

                """
            default:
                break
            }
        }

        let macroDeclPath = packagePath.appendingPathComponent("Sources/\(name)/\(name).swift")
        try macroDecls.write(to: macroDeclPath, atomically: true, encoding: .utf8)

        // Generate macro implementations
        var macroImpls = """
        import SwiftCompilerPlugin
        import SwiftSyntax
        import SwiftSyntaxBuilder
        import SwiftSyntaxMacros

        """

        for type in macroTypes {
            switch type {
            case "expression":
                macroImpls += """
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

                """
            case "attached":
                macroImpls += """
                public struct AddInitMacro: MemberMacro {
                    public static func expansion(
                        of node: AttributeSyntax,
                        providingMembersOf declaration: some DeclGroupSyntax,
                        in context: some MacroExpansionContext
                    ) throws -> [DeclSyntax] {
                        // Implementation to generate init
                        return []
                    }
                }

                """
            case "peer":
                macroImpls += """
                public struct AddPreviewMacro: PeerMacro {
                    public static func expansion(
                        of node: AttributeSyntax,
                        providingPeersOf declaration: some DeclSyntaxProtocol,
                        in context: some MacroExpansionContext
                    ) throws -> [DeclSyntax] {
                        // Implementation to generate preview
                        return []
                    }
                }

                """
            default:
                break
            }
        }

        // Generate plugin registration
        macroImpls += """
        @main
        struct \(name)Plugin: CompilerPlugin {
            let providingMacros: [Macro.Type] = [
        """

        let macroNames = macroTypes.map {
            switch $0 {
            case "expression": return "StringifyMacro.self"
            case "declaration": return "DeclareTypeMacro.self"
            case "attached": return "AddInitMacro.self"
            case "peer": return "AddPreviewMacro.self"
            default: return nil
            }
        }.compactMap { $0 }

        macroImpls += macroNames.joined(separator: ",
        ")
        macroImpls += """
        
    ]
}
"""

        let macroImplPath = packagePath.appendingPathComponent("Sources/\(name)Macros/\(name)Macro.swift")
        try macroImpls.write(to: macroImplPath, atomically: true, encoding: .utf8)

        // Generate client executable
        let clientContent = """
        import \(name)

        let a = 17
        let b = 25

        let (result, code) = #stringify(a + b)

        print("The value \(result) was produced by the code "\(code)"")
        """

        let clientPath = packagePath.appendingPathComponent("Sources/\(name)Client/main.swift")
        try clientContent.write(to: clientPath, atomically: true, encoding: .utf8)

        // Generate tests if requested
        if includeTests {
            let testContent = """
            import SwiftSyntaxMacros
            import SwiftSyntaxMacrosTestSupport
            import XCTest

            #if canImport(\(name)Macros)
            import \(name)Macros

            let testMacros: [String: Macro.Type] = [
                "stringify": StringifyMacro.self,
            ]
            #endif

            final class \(name)Tests: XCTestCase {
                func testMacro() throws {
                    #if canImport(\(name)Macros)
                    assertMacroExpansion(
                        """
                        #stringify(a + b)
                        """,
                        expandedSource: """
                        (a + b, "a + b")
                        """,
                        macros: testMacros
                    )
                    #else
                    throw XCTSkip("macros are only supported when running tests for the host platform")
                    #endif
                }
            }
            """

            let testPath = packagePath.appendingPathComponent("Tests/\(name)Tests/\(name)Tests.swift")
            try testContent.write(to: testPath, atomically: true, encoding: .utf8)
        }

        // Generate .gitignore
        let gitignore = """
        .DS_Store
        /.build
        /Packages
        /*.xcodeproj
        xcuserdata/
        DerivedData/
        .swiftpm/
        """

        let gitignorePath = packagePath.appendingPathComponent(".gitignore")
        try gitignore.write(to: gitignorePath, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "packageName": name,
            "path": packagePath.path,
            "macroTypes": macroTypes,
            "swiftSyntaxVersion": swiftSyntaxVersion,
            "includeTests": includeTests,
            "filesCreated": [
                "Package.swift",
                "Sources/\(name)/\(name).swift",
                "Sources/\(name)Macros/\(name)Macro.swift",
                "Sources/\(name)Client/main.swift",
                includeTests ? "Tests/\(name)Tests/\(name)Tests.swift" : nil,
                ".gitignore"
            ].compactMap { $0 }
        ]
    }

    private func generateMacroExpansionTest(_ args: [String: Any]) async throws -> Any {
        guard let macroName = args["macroName"] as? String,
              let inputCode = args["inputCode"] as? String else {
            throw MCPError.invalidParams
        }

        let expectedOutput = args["expectedOutput"] as? String
        let testFramework = args["testFramework"] as? String ?? "SwiftTesting"
        let testLibrary = args["testLibrary"] as? String ?? "PointFreeCo"

        var testCode = ""

        if testLibrary == "PointFreeCo" {
            // Point-Free MacroTesting library
            testCode = """
            import MacroTesting
            import Testing

            @Suite struct \(macroName)Tests {
                @Test func expansion() {
                    assertMacro {
                        """
            			\(inputCode)
            """
            """

            if let expected = expectedOutput {
                testCode += """

                        } matches: {
                            """
                			\(expected)
                """
                        }
                """
            }

            testCode += """
                    }
                }
            }
            """
        } else {
            // Apple's SwiftSyntaxMacrosTestSupport
            testCode = """
            import SwiftSyntaxMacros
            import SwiftSyntaxMacrosTestSupport

            #if canImport(\(macroName)Macros)
            import \(macroName)Macros

            let testMacros: [String: Macro.Type] = [
                "\(macroName.lowercased())": \(macroName)Macro.self,
            ]

            final class \(macroName)Tests: XCTestCase {
                func testMacro() throws {
                    assertMacroExpansion(
                        """
            			\(inputCode)
            """,
            """

            if let expected = expectedOutput {
                testCode += """
                        expandedSource: """
                			\(expected)
                """,
                """
            }

            testCode += """
                        macros: testMacros
                    )
                }
            }
            #endif
            """
        }

        return [
            "success": true,
            "testCode": testCode,
            "macroName": macroName,
            "framework": testFramework,
            "library": testLibrary
        ]
    }

    private func debugMacroExpansion(_ args: [String: Any]) async throws -> Any {
        guard let macroName = args["macroName"] as? String,
              let issue = args["issue"] as? String else {
            throw MCPError.invalidParams
        }

        let inputCode = args["inputCode"] as? String
        let errorMessage = args["errorMessage"] as? String

        var debuggingGuide = """
        # Debugging \(macroName) Macro

        ## Issue: \(issue)

        """

        if let error = errorMessage {
            debuggingGuide += """
            ## Error Message
            ```
            \(error)
            ```

            """
        }

        debuggingGuide += """
        ## Debugging Steps

        1. **Run tests with verbose output:**
           ```bash
           swift test --verbose
           ```

        2. **Build from command line to see full errors:**
           ```bash
           swift build 2>&1
           ```

        3. **Check macro registration in plugin:**
           Ensure your macro is registered in the `providingMacros` array.

        4. **Test macro expansion in isolation:**
           Use `assertMacroExpansion` to test the macro with exact input/output.

        5. **Add print statements in expansion method:**
           Since macros run at compile time, use:
           ```swift
           context.diagnose(.init(
               node: node,
               message: "Debug: value is \(value)"
           ))
           ```

        6. **Check for syntax errors in generated code:**
           The expanded code must be valid Swift syntax.

        ## Common Issues

        - **"failed to receive result from plugin"**: Macro crashed during expansion
        - **"cannot find macro"**: Macro not registered or module not imported
        - **"macro expansion produces invalid syntax"**: Generated code has syntax errors

        """

        return [
            "success": true,
            "debuggingGuide": debuggingGuide,
            "macroName": macroName,
            "issue": issue
        ]
    }

    private func createMacroDiagnostic(_ args: [String: Any]) async throws -> Any {
        guard let macroName = args["macroName"] as? String,
              let diagnostics = args["diagnostics"] as? [[String: String]] else {
            throw MCPError.invalidParams
        }

        var diagnosticCode = """
        import SwiftSyntax
        import SwiftSyntaxMacros

        enum \(macroName)Diagnostic: String, DiagnosticMessage {
        """

        for diag in diagnostics {
            if let id = diag["id"] {
                diagnosticCode += "
    case \(id)"
            }
        }

        diagnosticCode += """


            var message: String {
                switch self {
        """

        for diag in diagnostics {
            if let id = diag["id"], let message = diag["message"] {
                diagnosticCode += "
        case .\(id):
            return "\(message)""
            }
        }

        diagnosticCode += """

                }
            }

            var severity: DiagnosticSeverity {
                switch self {
        """

        for diag in diagnostics {
            if let id = diag["id"], let severity = diag["severity"] {
                diagnosticCode += "
        case .\(id):
            return .\(severity)"
            }
        }

        diagnosticCode += """

                }
            }
        }

        extension \(macroName)Diagnostic: FixItMessage {
            var fixItID: MessageID {
                MessageID(domain: "\(macroName)Macros", id: rawValue)
            }
        }
        """

        // Generate fix-it code
        var fixItCode = ""
        for diag in diagnostics {
            if let id = diag["id"],
               let fixItMessage = diag["fixItMessage"],
               let replacement = diag["replacementCode"] {
                fixItCode += """

                FixIt(
                    message: \(macroName)Diagnostic.\(id),
                    changes: [
                        .replace(
                            oldNode: Syntax(node),
                            newNode: Syntax(\(replacement))
                        )
                    ]
                )
                """
            }
        }

        return [
            "success": true,
            "diagnosticCode": diagnosticCode,
            "fixItCode": fixItCode,
            "macroName": macroName,
            "diagnosticCount": diagnostics.count
        ]
    }

    private func analyzeSwiftSyntax(_ args: [String: Any]) async throws -> Any {
        guard let code = args["code"] as? String else {
            throw MCPError.invalidParams
        }

        let analysisType = args["analysisType"] as? String ?? "all"

        // This would require actual SwiftSyntax parsing
        // For now, provide a basic analysis structure
        var analysis: [String: Any] = [:]

        switch analysisType {
        case "structure":
            analysis = [
                "type": "structure",
                "nodes": [
                    ["type": "SourceFile", "range": "0-\(code.count)"],
                    ["type": "CodeBlock", "range": "0-\(code.count)"]
                ]
            ]
        case "identifiers":
            let words = code.components(separatedBy: CharacterSet.alphanumerics.inverted)
            let identifiers = words.filter { $0.count > 1 && $0.first?.isUppercase == false }
            analysis = [
                "type": "identifiers",
                "identifiers": identifiers
            ]
        case "types":
            analysis = [
                "type": "types",
                "structs": [],
                "classes": [],
                "enums": [],
                "protocols": []
            ]
        case "functions":
            analysis = [
                "type": "functions",
                "functions": []
            ]
        default:
            analysis = [
                "type": "all",
                "summary": "Full AST analysis would require SwiftSyntax integration"
            ]
        }

        return [
            "success": true,
            "analysis": analysis,
            "analysisType": analysisType,
            "codeLength": code.count
        ]
    }
}
