# SwiftCoderMCP API Reference

Complete reference for all 50+ tools available in SwiftCoderMCP.

## Table of Contents
- [Project Tools](#project-tools)
- [Code Generation](#code-generation)
- [Package Management](#package-management)
- [Build & Test](#build--test)
- [Widget Development](#widget-development)
- [Macro Development](#macro-development)
- [Refactoring](#refactoring)
- [Scripting & CLI](#scripting--cli)
- [Templates](#templates)
- [Dependencies](#dependencies)
- [Testing](#testing)

---

## Project Tools

### create_swift_package
Create a new Swift package with specified type and configuration.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | ✅ | Package name |
| path | string | ✅ | Target directory path |
| packageType | enum | ✅ | Type: library, executable, tool, macro, plugin |
| platforms | array | ❌ | Target platforms (e.g., ["macOS(.v13)", "iOS(.v16)"]) |
| swiftVersion | string | ❌ | Swift tools version (default: "5.9") |
| includeTests | boolean | ❌ | Include test target (default: true) |
| dependencies | array | ❌ | Dependencies to add |

**Example:**
```json
{
  "name": "MyPackage",
  "path": "/Users/dev/projects",
  "packageType": "library",
  "platforms": ["macOS(.v13)", "iOS(.v16)"],
  "dependencies": [
    {
      "url": "https://github.com/Alamofire/Alamofire",
      "version": "5.8.0",
      "product": "Alamofire"
    }
  ]
}
```

### scaffold_project
Generate complete project structure with templates.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | ✅ | Project name |
| path | string | ✅ | Target directory |
| template | enum | ✅ | Template: cli-tool, swift-script, ios-app, macos-app, swiftui-widget, swift-macro, server-side, multiplatform |
| features | array | ❌ | Additional features |

**Templates:**
- `cli-tool`: Command-line tool with ArgumentParser
- `swift-script`: Standalone executable script
- `ios-app`: iOS application with SwiftUI
- `macos-app`: macOS application with SwiftUI
- `swiftui-widget`: WidgetKit extension
- `swift-macro`: Swift macro package
- `server-side`: Vapor server-side project
- `multiplatform`: Multiplatform Swift package

### add_target
Add a new target to existing Swift package.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| packagePath | string | ✅ | Path to Package.swift directory |
| targetName | string | ✅ | Name for new target |
| targetType | enum | ✅ | executable, library, test, plugin |
| dependencies | array | ❌ | Target dependencies |

### analyze_project
Analyze Swift project structure and dependencies.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| path | string | ✅ | Path to project |
| analysisType | enum | ❌ | structure, dependencies, complexity, all |

### setup_xcode_project
Configure Xcode project settings.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| path | string | ✅ | Project path |
| projectType | enum | ✅ | app, framework, extension, command-line |
| platforms | array | ❌ | Target platforms |
| capabilities | array | ❌ | App capabilities |

---

## Code Generation

### generate_struct
Generate Swift struct with Codable, Equatable, Hashable.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | ✅ | Struct name |
| properties | array | ✅ | Property definitions |
| conformances | array | ❌ | Protocols: Codable, Equatable, Hashable, Sendable |
| accessLevel | enum | ❌ | public, internal, private |
| generateInitializer | boolean | ❌ | Generate memberwise init |
| generateDescription | boolean | ❌ | Generate CustomStringConvertible |

**Property Definition:**
```json
{
  "name": "id",
  "type": "UUID",
  "isOptional": false,
  "isArray": false,
  "defaultValue": "UUID()"
}
```

### generate_enum
Generate Swift enum with associated values.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | ✅ | Enum name |
| cases | array | ✅ | Case definitions |
| rawType | string | ❌ | Raw value type (String, Int) |
| conformances | array | ❌ | Protocols |

### generate_protocol
Generate Swift protocol.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | ✅ | Protocol name |
| requirements | array | ❌ | Property/method requirements |
| inheritedProtocols | array | ❌ | Inherited protocols |
| associatedTypes | array | ❌ | Associated type definitions |

### generate_swiftui_view
Generate SwiftUI view with state management.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | ✅ | View name |
| stateVariables | array | ❌ | @State variables |
| observedObjects | array | ❌ | @ObservedObject properties |
| body | string | ❌ | View body content |
| previews | array | ❌ | Preview configurations |

### generate_test_cases
Generate XCTest or Swift Testing tests.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| targetName | string | ✅ | Target to test |
| testType | enum | ❌ | unit, integration, ui |
| framework | enum | ❌ | XCTest, SwiftTesting |
| coverage | array | ❌ | Methods to test |

### generate_mock
Generate mock implementations for protocols.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| protocolName | string | ✅ | Protocol to mock |
| methods | array | ❌ | Method signatures |
| trackCalls | boolean | ❌ | Track method calls |

---

## Package Management

### add_dependency
Add package dependency to Package.swift.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| packagePath | string | ✅ | Path to package |
| url | string | ✅ | Repository URL |
| version | string | ✅ | Version requirement |
| products | array | ❌ | Products to depend on |
| exactVersion | boolean | ❌ | Use exact version |
| branch | string | ❌ | Use specific branch |
| revision | string | ❌ | Use specific commit |

### remove_dependency
Remove dependency from Package.swift.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| packagePath | string | ✅ | Path to package |
| dependencyName | string | ✅ | Name of dependency |

### update_dependencies
Update dependencies to latest versions.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| packagePath | string | ✅ | Path to package |
| specificPackage | string | ❌ | Update only specific package |
| reset | boolean | ❌ | Reset package state |

### show_dependencies
Display dependency tree.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| packagePath | string | ✅ | Path to package |
| format | enum | ❌ | text, json, dot |

---

## Build & Test

### build_target
Build Swift package target.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| packagePath | string | ✅ | Path to package |
| target | string | ❌ | Specific target |
| configuration | enum | ❌ | debug, release |
| destination | string | ❌ | Build destination |
| verbose | boolean | ❌ | Verbose output |
| jobs | integer | ❌ | Parallel jobs |

### test_package
Run tests with filtering and coverage.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| packagePath | string | ✅ | Path to package |
| filter | string | ❌ | Test filter pattern |
| parallel | boolean | ❌ | Run in parallel |
| enableCodeCoverage | boolean | ❌ | Enable coverage |
| configuration | enum | ❌ | debug, release |

### benchmark_build
Run performance benchmarks.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| packagePath | string | ✅ | Path to package |
| iterations | integer | ❌ | Number of iterations |
| cleanBetween | boolean | ❌ | Clean between builds |

---

## Widget Development

### create_widget_extension
Create complete WidgetKit extension.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | ✅ | Widget name |
| appPath | string | ✅ | Path to host app |
| widgetKind | string | ❌ | Unique identifier |
| supportedFamilies | array | ❌ | Widget sizes |
| refreshInterval | integer | ❌ | Minutes between updates |
| includeConfiguration | boolean | ❌ | Add configuration intent |
| includeLiveActivity | boolean | ❌ | Include Live Activity |

**Supported Families:**
- `systemSmall`, `systemMedium`, `systemLarge`, `systemExtraLarge`
- `accessoryCircular`, `accessoryRectangular`, `accessoryInline`

### create_live_activity
Create Live Activity for Dynamic Island.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | ✅ | Activity name |
| attributes | array | ❌ | Activity attributes |
| states | array | ❌ | Supported states |

---

## Macro Development

### create_macro_package
Create complete macro package structure.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | ✅ | Package name |
| path | string | ✅ | Target directory |
| macroTypes | array | ❌ | expression, declaration, accessor, attached, peer, member |
| includeTests | boolean | ❌ | Include tests |
| swiftSyntaxVersion | string | ❌ | SwiftSyntax version |

### generate_macro_expansion_test
Generate test for macro expansion.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| macroName | string | ✅ | Macro to test |
| inputCode | string | ✅ | Input code |
| expectedOutput | string | ❌ | Expected expansion |
| testFramework | enum | ❌ | XCTest, SwiftTesting |
| testLibrary | enum | ❌ | Apple, PointFreeCo |

---

## Refactoring

### rename_symbol
Rename symbol across codebase.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| projectPath | string | ✅ | Project path |
| oldName | string | ✅ | Current name |
| newName | string | ✅ | New name |
| symbolType | enum | ✅ | variable, function, struct, class, enum, protocol, property |
| scope | enum | ❌ | file, target, project |

### extract_method
Extract code into new method.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| filePath | string | ✅ | Source file |
| startLine | integer | ✅ | Start line number |
| endLine | integer | ✅ | End line number |
| methodName | string | ✅ | New method name |
| accessLevel | enum | ❌ | private, internal, public |
| parameters | array | ❌ | Parameter names |

### format_code
Format Swift code.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| filePath | string | ✅ | File to format |
| formatter | enum | ❌ | swift-format, SwiftFormat |
| configuration | object | ❌ | Formatter options |
| inPlace | boolean | ❌ | Edit file in place |

### migrate_to_swift6
Assist with Swift 6 migration.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| projectPath | string | ✅ | Project path |
| enableConcurrency | boolean | ❌ | Enable strict concurrency |
| strictConcurrency | boolean | ❌ | Strict mode |
| enableCxxInterop | boolean | ❌ | Enable C++ interop |

---

## Scripting & CLI

### create_swift_script
Create standalone Swift script.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | ✅ | Script name |
| path | string | ✅ | Output directory |
| content | string | ❌ | Script content |
| dependencies | array | ❌ | Package dependencies |
| arguments | array | ❌ | Expected arguments |
| makeExecutable | boolean | ❌ | Make executable |

### create_cli_tool
Create CLI tool with ArgumentParser.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | ✅ | Tool name |
| path | string | ✅ | Output directory |
| arguments | array | ❌ | Command arguments |
| flags | array | ❌ | Command flags |
| subcommands | array | ❌ | Subcommands |

### create_shortcut_intent
Create AppIntent for Shortcuts.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | ✅ | Intent name |
| description | string | ✅ | Intent description |
| parameters | array | ❌ | Intent parameters |
| returnType | string | ❌ | Return type |
| performCode | string | ❌ | Implementation code |

---

## Templates

### apply_template
Apply predefined template.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| templateName | enum | ✅ | Template to apply |
| outputPath | string | ✅ | Output directory |
| projectName | string | ✅ | Project name |
| customizations | object | ❌ | Template-specific options |

**Available Templates:**
- `swift-script`, `cli-tool`, `ios-app`, `macos-app`
- `swiftui-widget`, `swift-macro`, `swift-package`
- `server-side`, `multiplatform`

### list_templates
List available templates.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| category | enum | ❌ | all, app, script, package, widget, macro |

---

## Dependencies

### analyze_dependencies
Full dependency analysis.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| projectPath | string | ✅ | Project path |
| analysisType | enum | ❌ | full, conflicts, unused, outdated, security |
| includeTransitive | boolean | ❌ | Include transitive deps |

### check_vulnerabilities
Check for security vulnerabilities.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| projectPath | string | ✅ | Project path |
| severityThreshold | enum | ❌ | low, medium, high, critical |

### suggest_updates
Suggest dependency updates.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| projectPath | string | ✅ | Project path |
| updateType | enum | ❌ | all, major, minor, patch |
| includeBreakingChanges | boolean | ❌ | Include breaking changes |

---

## Testing

### generate_unit_tests
Generate unit tests.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| sourceFile | string | ✅ | File to test |
| testFramework | enum | ❌ | XCTest, SwiftTesting |
| coverage | enum | ❌ | basic, comprehensive, edge_cases |
| outputPath | string | ❌ | Output directory |
| mockDependencies | boolean | ❌ | Generate mocks |

### generate_snapshot_tests
Generate snapshot tests for SwiftUI.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| viewFiles | array | ✅ | View files to test |
| devices | array | ❌ | iPhone15, iPadPro, etc. |
| themes | array | ❌ | light, dark |
| outputPath | string | ❌ | Output directory |

### analyze_test_coverage
Analyze test coverage.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| projectPath | string | ✅ | Project path |
| target | string | ❌ | Specific target |
| format | enum | ❌ | text, json, html |

---

## Response Formats

All tools return a JSON response with the following structure:

```json
{
  "success": true,
  "message": "Operation completed",
  "data": { ... }
}
```

Or on error:

```json
{
  "success": false,
  "error": "Error description",
  "code": "ERROR_CODE"
}
```

## Error Codes

| Code | Description |
|------|-------------|
| INVALID_PARAMS | Missing or invalid parameters |
| FILE_NOT_FOUND | Specified file not found |
| BUILD_FAILED | Build operation failed |
| PERMISSION_DENIED | Insufficient permissions |
| NETWORK_ERROR | Network operation failed |
| UNKNOWN_ERROR | Unexpected error |

---

For more examples, see [EXAMPLES.md](EXAMPLES.md)
