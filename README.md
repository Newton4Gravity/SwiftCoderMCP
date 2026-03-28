# SwiftCoderMCP

A comprehensive Swift Coding MCP (Model Context Protocol) Server with 50+ tools for creating scripts, shortcuts, widgets, apps, and managing Swift projects through AI assistants.

## 🚀 Features

- **Project Scaffolding**: Create Swift packages, apps, widgets, and macros with templates
- **Code Generation**: Generate structs, enums, protocols, SwiftUI views, and tests
- **Package Management**: Manage SPM dependencies, updates, and conflicts
- **Build Automation**: Build, test, and archive with advanced options
- **Widget Development**: Create WidgetKit extensions and Live Activities
- **Macro Development**: Build Swift macros with full debugging support
- **Code Refactoring**: Rename symbols, extract methods, format code
- **Scripting**: Create CLI tools, Swift scripts, and Shortcuts integration
- **Testing**: Generate unit tests, snapshot tests, and performance benchmarks

## 📦 Installation

### Prerequisites

- Swift 5.9+ (`swift --version`)
- Git
- Network access for Swift Package Manager dependencies

> **Raspberry Pi 4 support:** this project is designed to run on Linux ARM64 (including Raspberry Pi OS 64-bit on Pi 4) as long as a compatible Swift toolchain is installed.

---

### Raspberry Pi 4 (recommended flow)

1. **Use a 64-bit OS image** (Raspberry Pi OS 64-bit Bookworm or Ubuntu Server 22.04/24.04 ARM64).
2. **Install Swift** for Linux ARM64 from the official Swift download instructions:
   - https://www.swift.org/download/
3. **Verify toolchain**:
   ```bash
   swift --version
   ```
4. **Clone and build**:
   ```bash
   git clone <your-fork-or-repo-url>
   cd SwiftCoderMCP
   ./build.sh
   ```
5. **Install binary**:
   ```bash
   sudo cp .build/release/swift-coder-mcp /usr/local/bin/
   ```
6. **Run diagnostics**:
   ```bash
   ./diagnose.sh
   swift-coder-mcp --version
   ```

---

### macOS / Linux build from source

```bash
git clone <your-fork-or-repo-url>
cd SwiftCoderMCP
./build.sh
sudo cp .build/release/swift-coder-mcp /usr/local/bin/
```

### Optional installer script

If you already built the binary, you can install with:

```bash
./install.sh --build
```

### Troubleshooting tips for Pi 4

- If build memory is tight, reduce parallelism:
  ```bash
  swift build -c release -j 2
  ```
- Ensure your shell can find Swift (`which swift`) and the installed binary (`which swift-coder-mcp`).
- If dependencies fail to resolve, re-run:
  ```bash
  swift package resolve
  ```

## 🛠️ Available Tools (50+)

### Project Management
- `create_swift_package` - Create new Swift packages
- `scaffold_project` - Generate complete project structures
- `add_target` - Add targets to existing packages
- `analyze_project` - Analyze project structure and dependencies
- `setup_xcode_project` - Configure Xcode project settings

### Code Generation
- `generate_struct` - Generate structs with Codable/Equatable
- `generate_enum` - Generate enums with associated values
- `generate_protocol` - Generate protocols with requirements
- `generate_extension` - Generate extensions
- `generate_swiftui_view` - Generate SwiftUI views with previews
- `generate_test_cases` - Generate XCTest/Swift Testing tests
- `generate_mock` - Generate mock implementations

### Package Management
- `add_dependency` - Add package dependencies
- `remove_dependency` - Remove dependencies
- `update_dependencies` - Update to latest versions
- `resolve_dependencies` - Resolve without updating
- `show_dependencies` - Display dependency tree
- `edit_package` - Modify Package.swift
- `clean_package` - Clean build artifacts

### Build & Test
- `build_target` - Build with configuration options
- `run_executable` - Build and run executables
- `test_package` - Run tests with coverage
- `archive_build` - Create archives for distribution
- `benchmark_build` - Performance benchmark builds
- `check_compatibility` - Check API compatibility

### Widget Development
- `create_widget_extension` - Create WidgetKit extensions
- `create_intent_configuration` - Configurable widgets
- `create_live_activity` - Dynamic Island/Lock Screen activities
- `generate_widget_preview` - Xcode preview code
- `create_app_clip` - App Clip with associated domains

### Macro Development
- `create_macro_package` - Full macro package structure
- `generate_macro_expansion_test` - Test macro expansions
- `debug_macro_expansion` - Debug macro issues
- `create_macro_diagnostic` - Diagnostic messages and fix-its
- `analyze_swift_syntax` - SwiftSyntax AST analysis

### Refactoring
- `rename_symbol` - Rename across codebase
- `extract_method` - Extract to new method
- `extract_variable` - Extract to variable
- `organize_imports` - Sort and organize imports
- `format_code` - Format with swift-format
- `migrate_to_swift6` - Swift 6 migration assistance

### Scripting & CLI
- `create_swift_script` - Executable Swift scripts
- `create_shortcut_intent` - Shortcuts app integration
- `create_cli_tool` - ArgumentParser CLI tools
- `create_automation_script` - macOS automation
- `bundle_script` - Bundle as standalone executable

### Templates
- `apply_template` - Use predefined templates
- `create_template` - Create custom templates
- `list_templates` - List available templates
- `customize_template` - Modify templates

### Dependencies
- `analyze_dependencies` - Full dependency analysis
- `check_vulnerabilities` - Security vulnerability check
- `suggest_updates` - Update suggestions
- `generate_dependency_report` - Reports in multiple formats

### Testing
- `generate_unit_tests` - XCTest/Swift Testing tests
- `generate_snapshot_tests` - Snapshot testing setup
- `generate_performance_tests` - Performance benchmarks
- `analyze_test_coverage` - Coverage analysis

## 💡 Example Usage

### Create a new iOS app
```json
{
  "tool": "scaffold_project",
  "arguments": {
    "name": "MyApp",
    "path": "/Users/dev/projects",
    "template": "ios-app",
    "features": ["swiftui", "widget"]
  }
}
```

### Generate a SwiftUI view
```json
{
  "tool": "generate_swiftui_view",
  "arguments": {
    "name": "UserProfileView",
    "stateVariables": [
      {"name": "user", "type": "User", "initialValue": "User()"}
    ],
    "body": "VStack { Text(user.name) }"
  }
}
```

### Create a CLI tool
```json
{
  "tool": "create_cli_tool",
  "arguments": {
    "name": "FileFinder",
    "path": "/Users/dev/tools",
    "arguments": [
      {"name": "pattern", "type": "String", "help": "Search pattern"}
    ],
    "flags": [
      {"name": "recursive", "help": "Search recursively"}
    ]
  }
}
```

### Add a dependency
```json
{
  "tool": "add_dependency",
  "arguments": {
    "packagePath": "/Users/dev/MyProject",
    "url": "https://github.com/Alamofire/Alamofire",
    "version": "5.8.0",
    "products": ["Alamofire"]
  }
}
```

## 🔧 Configuration

### Claude Desktop
Add to `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "swift-coder": {
      "command": "/usr/local/bin/swift-coder-mcp",
      "args": [],
      "env": {
        "SWIFT_CODER_TEMPLATES": "~/.swift-coder-mcp/templates"
      }
    }
  }
}
```

### Cursor
Add to `.cursor/mcp.json`:
```json
{
  "servers": [
    {
      "name": "swift-coder",
      "command": "/usr/local/bin/swift-coder-mcp"
    }
  ]
}
```

## 📚 Documentation

- [Installation Guide](INSTALLATION_GUIDE.md)
- [Quick Start](QUICKSTART.md)
- [API Reference](API_REFERENCE.md)
- [Examples](EXAMPLES.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🙏 Acknowledgments

- [Swift ArgumentParser](https://github.com/apple/swift-argument-parser)
- [SwiftSyntax](https://github.com/apple/swift-syntax)
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk)
