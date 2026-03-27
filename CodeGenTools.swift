import MCP
import Foundation

// MARK: - Code Generation Tools

struct CodeGenTools: ToolProvider {
    var tools: [Tool] {
        [
            Tool(
                name: "generate_struct",
                description: "Generate Swift struct with Codable, Equatable, Hashable conformance",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "properties": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "type": ["type": "string"],
                                    "isOptional": ["type": "boolean"],
                                    "isArray": ["type": "boolean"],
                                    "defaultValue": ["type": "string"]
                                ]
                            ]
                        ],
                        "conformances": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "Protocols to conform to (Codable, Equatable, Hashable, Sendable, etc.)"
                        ],
                        "accessLevel": [
                            "type": "string",
                            "enum": ["public", "internal", "private"],
                            "default": "internal"
                        ],
                        "generateInitializer": ["type": "boolean", "default": true],
                        "generateDescription": ["type": "boolean", "default": false]
                    ],
                    "required": ["name", "properties"]
                ]
            ),
            Tool(
                name: "generate_enum",
                description: "Generate Swift enum with associated values and allCases",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "cases": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "associatedValues": [
                                        "type": "array",
                                        "items": [
                                            "type": "object",
                                            "properties": [
                                                "name": ["type": "string"],
                                                "type": ["type": "string"]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        "rawType": ["type": "string", "description": "Raw value type (String, Int, etc.)"],
                        "conformances": ["type": "array", "items": ["type": "string"]]
                    ],
                    "required": ["name", "cases"]
                ]
            ),
            Tool(
                name: "generate_protocol",
                description: "Generate Swift protocol with requirements and default implementations",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "requirements": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "type": ["enum": ["property", "method"]],
                                    "name": ["type": "string"],
                                    "signature": ["type": "string"],
                                    "isOptional": ["type": "boolean"]
                                ]
                            ]
                        ],
                        "inheritedProtocols": ["type": "array", "items": ["type": "string"]],
                        "associatedTypes": ["type": "array", "items": ["type": "string"]]
                    ],
                    "required": ["name"]
                ]
            ),
            Tool(
                name: "generate_extension",
                description: "Generate Swift extension with computed properties and methods",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "typeName": ["type": "string"],
                        "protocolConformance": ["type": "string"],
                        "computedProperties": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "type": ["type": "string"],
                                    "getter": ["type": "string"]
                                ]
                            ]
                        ],
                        "methods": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "signature": ["type": "string"],
                                    "body": ["type": "string"]
                                ]
                            ]
                        ]
                    ],
                    "required": ["typeName"]
                ]
            ),
            Tool(
                name: "generate_swiftui_view",
                description: "Generate SwiftUI view with state management and previews",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "stateVariables": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "type": ["type": "string"],
                                    "initialValue": ["type": "string"]
                                ]
                            ]
                        ],
                        "observedObjects": ["type": "array", "items": ["type": "string"]],
                        "body": ["type": "string", "description": "View body content"],
                        "previews": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "state": ["type": "object"]
                                ]
                            ]
                        ]
                    ],
                    "required": ["name"]
                ]
            ),
            Tool(
                name: "generate_test_cases",
                description: "Generate XCTest or Swift Testing test cases for existing code",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "targetName": ["type": "string"],
                        "testType": [
                            "type": "string",
                            "enum": ["unit", "integration", "ui"],
                            "default": "unit"
                        ],
                        "framework": [
                            "type": "string",
                            "enum": ["XCTest", "SwiftTesting"],
                            "default": "SwiftTesting"
                        ],
                        "coverage": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "Methods to test"
                        ]
                    ],
                    "required": ["targetName"]
                ]
            ),
            Tool(
                name: "generate_mock",
                description: "Generate mock implementations for protocols",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "protocolName": ["type": "string"],
                        "methods": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "signature": ["type": "string"],
                                    "returnType": ["type": "string"]
                                ]
                            ]
                        ],
                        "trackCalls": ["type": "boolean", "default": true]
                    ],
                    "required": ["protocolName"]
                ]
            ),
        ]
    }

    func handle(_ name: String, arguments: [String: Any]) async throws -> Any {
        switch name {
        case "generate_struct":
            return try await generateStruct(arguments)
        case "generate_enum":
            return try await generateEnum(arguments)
        case "generate_protocol":
            return try await generateProtocol(arguments)
        case "generate_extension":
            return try await generateExtension(arguments)
        case "generate_swiftui_view":
            return try await generateSwiftUIView(arguments)
        case "generate_test_cases":
            return try await generateTestCases(arguments)
        case "generate_mock":
            return try await generateMock(arguments)
        default:
            throw MCPError.methodNotFound
        }
    }

    // MARK: - Implementation

    private func generateStruct(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String,
              let properties = args["properties"] as? [[String: Any]] else {
            throw MCPError.invalidParams
        }

        let conformances = args["conformances"] as? [String] ?? ["Codable"]
        let accessLevel = args["accessLevel"] as? String ?? "internal"
        let generateInit = args["generateInitializer"] as? Bool ?? true
        let generateDescription = args["generateDescription"] as? Bool ?? false

        var code = """
        \(accessLevel == "internal" ? "" : "\(accessLevel) ")struct \(name): \(conformances.joined(separator: ", ")) {
        """

        // Properties
        for prop in properties {
            guard let propName = prop["name"] as? String,
                  let propType = prop["type"] as? String else { continue }

            let isOptional = prop["isOptional"] as? Bool ?? false
            let isArray = prop["isArray"] as? Bool ?? false
            let defaultValue = prop["defaultValue"] as? String

            var typeString = propType
            if isArray { typeString = "[\(propType)]" }
            if isOptional { typeString = "\(typeString)?" }

            let defaultSuffix = defaultValue != nil ? " = \(defaultValue!)" : ""
            code += """

            	let \(propName): \(typeString)\(defaultSuffix)
            """
        }

        // Memberwise initializer
        if generateInit {
            code += """


            	init(
            """
            for (index, prop) in properties.enumerated() {
                guard let propName = prop["name"] as? String,
                      let propType = prop["type"] as? String else { continue }

                let isOptional = prop["isOptional"] as? Bool ?? false
                let isArray = prop["isArray"] as? Bool ?? false
                var typeString = propType
                if isArray { typeString = "[\(propType)]" }
                if isOptional { typeString = "\(typeString)?" }

                let comma = index < properties.count - 1 ? "," : ""
                code += "
		\(propName): \(typeString)\(comma)"
            }
            code += "
	) {"
            for prop in properties {
                guard let propName = prop["name"] as? String else { continue }
                code += "
		self.\(propName) = \(propName)"
            }
            code += "
	}"
        }

        // Custom description
        if generateDescription {
            code += """


            	var description: String {
            		return "\(name)(\(
            """
            let propNames = properties.compactMap { $0["name"] as? String }
            code += propNames.map { "\($0): \(\($0))" }.joined(separator: ", ")
            code += ")"
	}"
        }

        code += "
}"

        return [
            "success": true,
            "code": code,
            "type": "struct",
            "name": name
        ]
    }

    private func generateEnum(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String,
              let cases = args["cases"] as? [[String: Any]] else {
            throw MCPError.invalidParams
        }

        let rawType = args["rawType"] as? String
        let conformances = args["conformances"] as? [String] ?? []

        var protocolList = conformances
        if rawType != nil && !protocolList.contains("RawRepresentable") {
            protocolList.append("RawRepresentable")
        }

        var code = "enum \(name)"
        if let raw = rawType {
            code += ": \(raw)"
        }
        if !protocolList.isEmpty {
            code += rawType != nil ? ", \(protocolList.joined(separator: ", "))" : ": \(protocolList.joined(separator: ", "))"
        }
        code += " {"

        for enumCase in cases {
            guard let caseName = enumCase["name"] as? String else { continue }

            code += "
	case \(caseName)"

            if let associatedValues = enumCase["associatedValues"] as? [[String: String]], !associatedValues.isEmpty {
                let params = associatedValues.map { "\($0["name"] ?? ""): \($0["type"] ?? "")" }.joined(separator: ", ")
                code += "(\(params))"
            }

            if let rawValue = enumCase["rawValue"] as? String, rawType != nil {
                code += " = \(rawValue)"
            }
        }

        // Generate allCases if CaseIterable
        if conformances.contains("CaseIterable") && rawType != nil {
            code += "

	static var allCases: [\(name)] {"
            code += "
		return ["
            let caseNames = cases.compactMap { $0["name"] as? String }
            code += caseNames.map { ".\($0)" }.joined(separator: ", ")
            code += "]
	}"
        }

        code += "
}"

        return [
            "success": true,
            "code": code,
            "type": "enum",
            "name": name
        ]
    }

    private func generateProtocol(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String else {
            throw MCPError.invalidParams
        }

        let requirements = args["requirements"] as? [[String: Any]] ?? []
        let inheritedProtocols = args["inheritedProtocols"] as? [String] ?? []
        let associatedTypes = args["associatedTypes"] as? [String] ?? []

        var code = "protocol \(name)"
        if !inheritedProtocols.isEmpty {
            code += ": \(inheritedProtocols.joined(separator: ", "))"
        }
        code += " {"

        // Associated types
        for type in associatedTypes {
            code += "
	associatedtype \(type)"
        }

        if !associatedTypes.isEmpty && !requirements.isEmpty {
            code += "
"
        }

        // Requirements
        for req in requirements {
            let isOptional = req["isOptional"] as? Bool ?? false
            let prefix = isOptional ? "@objc optional " : ""

            if let reqName = req["name"] as? String,
               let reqType = req["type"] as? String {
                if reqType == "property" {
                    if let signature = req["signature"] as? String {
                        code += "
	\(prefix)var \(reqName): \(signature) { get }"
                    }
                } else if reqType == "method" {
                    if let signature = req["signature"] as? String {
                        code += "
	\(prefix)func \(signature)"
                    }
                }
            }
        }

        code += "
}"

        return [
            "success": true,
            "code": code,
            "type": "protocol",
            "name": name
        ]
    }

    private func generateExtension(_ args: [String: Any]) async throws -> Any {
        guard let typeName = args["typeName"] as? String else {
            throw MCPError.invalidParams
        }

        let protocolConformance = args["protocolConformance"] as? String
        let computedProperties = args["computedProperties"] as? [[String: String]] ?? []
        let methods = args["methods"] as? [[String: String]] ?? []

        var code = "extension \(typeName)"
        if let proto = protocolConformance {
            code += ": \(proto)"
        }
        code += " {"

        for prop in computedProperties {
            if let name = prop["name"], let type = prop["type"], let getter = prop["getter"] {
                code += """

                	var \(name): \(type) {
                		\(getter)
                	}
                """
            }
        }

        for method in methods {
            if let signature = method["signature"], let body = method["body"] {
                code += """

                	func \(signature) {
                		\(body)
                	}
                """
            }
        }

        code += "
}"

        return [
            "success": true,
            "code": code,
            "type": "extension",
            "target": typeName
        ]
    }

    private func generateSwiftUIView(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String else {
            throw MCPError.invalidParams
        }

        let stateVars = args["stateVariables"] as? [[String: String]] ?? []
        let observedObjects = args["observedObjects"] as? [String] ?? []
        let body = args["body"] as? String ?? "Text("Hello, \(name)!")"
        let previews = args["previews"] as? [[String: Any]] ?? []

        var code = "import SwiftUI

"
        code += "struct \(name): View {"

        // State variables
        for state in stateVars {
            if let stateName = state["name"], let stateType = state["type"] {
                let initialValue = state["initialValue"] ?? ""
                code += "
	@State private var \(stateName): \(stateType) = \(initialValue)"
            }
        }

        // Observed objects
        for obj in observedObjects {
            code += "
	@ObservedObject var \(obj.lowercased()): \(obj)"
        }

        // Body
        code += "

	var body: some View {"
        code += "
		\(body)"
        code += "
	}
}
"

        // Previews
        if previews.isEmpty {
            code += """

            #Preview {
                \(name)()
            }
            """
        } else {
            for preview in previews {
                if let previewName = preview["name"] as? String {
                    code += """

                    #Preview("\(previewName)") {
                        \(name)()
                    }
                    """
                }
            }
        }

        return [
            "success": true,
            "code": code,
            "type": "swiftui_view",
            "name": name
        ]
    }

    private func generateTestCases(_ args: [String: Any]) async throws -> Any {
        guard let targetName = args["targetName"] as? String else {
            throw MCPError.invalidParams
        }

        let testType = args["testType"] as? String ?? "unit"
        let framework = args["framework"] as? String ?? "SwiftTesting"
        let coverage = args["coverage"] as? [String] ?? []

        var code = ""

        if framework == "SwiftTesting" {
            code = "import Testing
@testable import \(targetName)

"
            code += "struct \(targetName)Tests {
"

            if coverage.isEmpty {
                code += """

                	@Test func example() async throws {
                		// Write your test here and use APIs like `#expect(...)` to check expected conditions.
                	}
                """
            } else {
                for method in coverage {
                    code += """

                    	@Test func \(method)() async throws {
                		// Test \(method) implementation
                		#expect(true)
                	}
                    """
                }
            }
        } else {
            code = "import XCTest
@testable import \(targetName)

"
            code += "final class \(targetName)Tests: XCTestCase {
"

            if coverage.isEmpty {
                code += """

                	func testExample() throws {
                		// Write your test here
                		XCTAssertTrue(true)
                	}
                """
            } else {
                for method in coverage {
                    code += """

                	func test\(method.capitalized)() throws {
                		// Test \(method) implementation
                		XCTAssertTrue(true)
                	}
                    """
                }
            }
        }

        code += "
}"

        return [
            "success": true,
            "code": code,
            "framework": framework,
            "testType": testType
        ]
    }

    private func generateMock(_ args: [String: Any]) async throws -> Any {
        guard let protocolName = args["protocolName"] as? String else {
            throw MCPError.invalidParams
        }

        let methods = args["methods"] as? [[String: String]] ?? []
        let trackCalls = args["trackCalls"] as? Bool ?? true

        let mockName = "Mock\(protocolName)"

        var code = "class \(mockName): \(protocolName) {"

        if trackCalls {
            code += "
	// Call tracking"
            for method in methods {
                if let methodName = method["signature"]?.components(separatedBy: "(").first {
                    code += "
	var \(methodName)Called = false"
                    code += "
	var \(methodName)CallCount = 0"
                }
            }
        }

        code += "

	// Return values"
        for method in methods {
            if let returnType = method["returnType"], !returnType.isEmpty, returnType != "Void" {
                let methodName = method["signature"]?.components(separatedBy: "(").first ?? ""
                code += "
	var \(methodName)ReturnValue: \(returnType)!"
            }
        }

        code += "
"
        for method in methods {
            if let signature = method["signature"] {
                code += "
	func \(signature) {"

                if trackCalls {
                    let methodName = signature.components(separatedBy: "(").first ?? ""
                    code += "
		\(methodName)Called = true"
                    code += "
		\(methodName)CallCount += 1"
                }

                if let returnType = method["returnType"], !returnType.isEmpty, returnType != "Void" {
                    let methodName = signature.components(separatedBy: "(").first ?? ""
                    code += "
		return \(methodName)ReturnValue"
                }

                code += "
	}"
            }
        }

        code += "
}"

        return [
            "success": true,
            "code": code,
            "mockName": mockName,
            "protocol": protocolName
        ]
    }
}
