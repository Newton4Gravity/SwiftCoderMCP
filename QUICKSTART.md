# SwiftCoderMCP Quick Start Guide

Get up and running with SwiftCoderMCP in 5 minutes.

## 1. Installation (1 minute)

```bash
# Quick install
curl -fsSL https://raw.githubusercontent.com/yourusername/SwiftCoderMCP/main/Scripts/install.sh | bash

# Verify
swift-coder-mcp --version
```

## 2. Configure Your AI Client (2 minutes)

### Claude Desktop
Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "swift-coder": {
      "command": "/usr/local/bin/swift-coder-mcp"
    }
  }
}
```
**Restart Claude Desktop**

### Cursor
Add to `~/.cursor/mcp.json`:
```json
{
  "mcpServers": {
    "swift-coder": {
      "command": "/usr/local/bin/swift-coder-mcp"
    }
  }
}
```

## 3. Try These Commands (2 minutes)

### Create a Swift Package
Ask your AI:
> "Create a Swift package called 'DataKit' for handling JSON data"

### Generate a SwiftUI View
> "Generate a UserProfileView with name, email, and avatar"

### Build a CLI Tool
> "Create a CLI tool 'filefinder' that searches for files by pattern"

### Add Dependencies
> "Add Alamofire to my project at ~/Projects/MyApp"

## 4. Common Workflows

### Start a New iOS App
```
"Create an iOS app called 'TaskManager' with:
- SwiftUI interface
- Core Data for persistence
- Widget for home screen
- Push notifications"
```

### Create a Swift Macro
```
"Create a Swift macro package 'AutoCodable' that automatically
generates Codable conformance for structs"
```

### Refactor Existing Code
```
"Extract the networking code from MyViewController into
a separate NetworkManager class"
```

### Generate Tests
```
"Generate unit tests for all public methods in my DataService class"
```

## 5. Tips for Best Results

### Be Specific
- ✅ "Create a CLI tool with arguments for input file and output directory"
- ❌ "Make a command line tool"

### Include Context
- ✅ "Add dependency https://github.com/Alamofire/Alamofire version 5.8.0 to my project at ~/Projects/MyApp"
- ❌ "Add Alamofire"

### Use Template Names
- ✅ "Apply the swiftui-widget template for a weather widget"
- ❌ "Create a widget"

### Specify Platforms
- ✅ "Create a multiplatform package supporting iOS 16, macOS 13, and watchOS 9"
- ❌ "Create a Swift package"

## 6. Next Steps

- Browse all [50+ available tools](API_REFERENCE.md)
- See detailed [examples](EXAMPLES.md)
- Read the [full installation guide](INSTALLATION_GUIDE.md)
- Check [troubleshooting tips](INSTALLATION_GUIDE.md#troubleshooting)

## 7. Quick Reference Card

| Task | Example Prompt |
|------|---------------|
| **New Package** | "Create a library package 'NetworkKit' with Alamofire dependency" |
| **New App** | "Create an iOS app 'PhotoGallery' with camera access and photo grid" |
| **CLI Tool** | "Create a CLI tool 'loganalyzer' that parses log files and shows statistics" |
| **Widget** | "Create a widget showing daily step count from HealthKit" |
| **Macro** | "Create a macro that adds a memberwise initializer to structs" |
| **Script** | "Create a Swift script that backs up all .swift files in a directory" |
| **Refactor** | "Rename all instances of 'oldName' to 'newName' in my project" |
| **Test** | "Generate unit tests for my Calculator class with edge cases" |
| **Format** | "Format all Swift files in my project using swift-format" |
| **Dependencies** | "Show me all dependencies and check for outdated packages" |

## 8. Getting Help

Stuck? Try these:

1. **Run diagnostics:**
   ```bash
   ./Scripts/diagnose.sh
   ```

2. **Check logs:**
   ```bash
   tail -f ~/Library/Logs/Claude/mcp-server-swift-coder.log
   ```

3. **Test manually:**
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | swift-coder-mcp
   ```

4. **Open an issue:**
   [GitHub Issues](https://github.com/yourusername/SwiftCoderMCP/issues)

---

**You're ready to code with AI! 🚀**
