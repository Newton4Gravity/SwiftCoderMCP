# SwiftCoderMCP Installation Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Install](#quick-install)
3. [Build from Source](#build-from-source)
4. [Client Configuration](#client-configuration)
5. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required
- **macOS 13.0+** or **Linux** with Swift support
- **Swift 5.9+** ([Download](https://swift.org/download/))
- **Git** for cloning the repository

### Optional
- **Xcode 15+** (for iOS/macOS development features)
- **Docker** (for containerized builds)

## Quick Install

### Using Install Script (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/SwiftCoderMCP/main/Scripts/install.sh | bash
```

### Verify Installation
```bash
swift-coder-mcp --version
swift-coder-mcp --help
```

## Build from Source

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/SwiftCoderMCP.git
cd SwiftCoderMCP
```

### 2. Build Release Binary
```bash
./Scripts/build.sh
```

Options:
- `--test` or `-t`: Run tests after building
- `--package` or `-p`: Create distribution package

### 3. Manual Installation
```bash
sudo cp .build/release/swift-coder-mcp /usr/local/bin/
```

### 4. Verify
```bash
which swift-coder-mcp
swift-coder-mcp --version
```

## Client Configuration

### Claude Desktop

**macOS:**
```bash
# Edit config file
nano ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

**Configuration:**
```json
{
  "mcpServers": {
    "swift-coder": {
      "command": "/usr/local/bin/swift-coder-mcp",
      "args": [],
      "env": {
        "SWIFT_CODER_TEMPLATES": "~/.swift-coder-mcp/templates",
        "SWIFT_CODER_LOG_LEVEL": "info"
      }
    }
  }
}
```

**Windows:**
```json
{
  "mcpServers": {
    "swift-coder": {
      "command": "C:\\Program Files\\SwiftCoderMCP\\swift-coder-mcp.exe",
      "args": []
    }
  }
}
```

**Important:** Restart Claude Desktop after configuration changes.

### Cursor

**Global Config** (`~/.cursor/mcp.json`):
```json
{
  "mcpServers": {
    "swift-coder": {
      "command": "/usr/local/bin/swift-coder-mcp",
      "args": []
    }
  }
}
```

**Project Config** (`.cursor/mcp.json` in project root):
```json
{
  "mcpServers": {
    "swift-coder": {
      "command": "/usr/local/bin/swift-coder-mcp",
      "args": [],
      "env": {
        "PROJECT_PATH": "${workspaceFolder}"
      }
    }
  }
}
```

Cursor supports hot-reload - no restart needed.

### VS Code (with Cline/Continue)

**Cline Config** (`~/Library/Application\ Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`):
```json
{
  "mcpServers": {
    "swift-coder": {
      "command": "/usr/local/bin/swift-coder-mcp",
      "args": [],
      "env": {}
    }
  }
}
```

**Continue Config** (`~/.continue/config.json`):
```json
{
  "mcpServers": [
    {
      "name": "swift-coder",
      "command": "/usr/local/bin/swift-coder-mcp",
      "args": []
    }
  ]
}
```

### Zed

Add to `~/.config/zed/settings.json`:
```json
{
  "context_servers": {
    "swift-coder": {
      "command": {
        "path": "/usr/local/bin/swift-coder-mcp",
        "args": [],
        "env": {}
      }
    }
  }
}
```

## Troubleshooting

### Common Issues

#### "command not found: swift-coder-mcp"
```bash
# Check if binary exists
ls -la /usr/local/bin/swift-coder-mcp

# Add to PATH if needed
export PATH="/usr/local/bin:$PATH"

# Or use full path
/usr/local/bin/swift-coder-mcp --version
```

#### "Permission denied"
```bash
# Fix permissions
sudo chmod +x /usr/local/bin/swift-coder-mcp
```

#### "Failed to receive result from plugin" (Claude Desktop)
1. Check logs: `tail -f ~/Library/Logs/Claude/mcp-server-swift-coder.log`
2. Verify binary works standalone: `swift-coder-mcp --version`
3. Restart Claude Desktop

#### Build Failures
```bash
# Clean and rebuild
swift package clean
swift package resolve
swift build -c release
```

### Diagnostic Tool
Run the built-in diagnostic:
```bash
./Scripts/diagnose.sh
```

This checks:
- Swift installation
- Binary location
- Environment variables
- Network connectivity
- Client configurations

### Getting Help

1. **Check Logs:**
   - Claude Desktop: `~/Library/Logs/Claude/`
   - Cursor: Built-in MCP panel

2. **Verify MCP Protocol:**
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | swift-coder-mcp
   ```

3. **Test with MCP Inspector:**
   ```bash
   npx @modelcontextprotocol/inspector swift-coder-mcp
   ```

4. **GitHub Issues:**
   [github.com/yourusername/SwiftCoderMCP/issues](https://github.com/yourusername/SwiftCoderMCP/issues)

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SWIFT_CODER_TEMPLATES` | Custom templates directory | `~/.swift-coder-mcp/templates` |
| `SWIFT_CODER_LOG_LEVEL` | Logging level (debug/info/warn/error) | `info` |
| `SWIFT_CODER_MAX_CONCURRENT` | Max concurrent operations | `4` |

## Uninstallation

```bash
# Remove binary
sudo rm /usr/local/bin/swift-coder-mcp

# Remove config
rm -rf ~/.swift-coder-mcp

# Remove from client configs
# Edit claude_desktop_config.json, .cursor/mcp.json, etc.
```

## Next Steps

- Read the [Quick Start Guide](QUICKSTART.md)
- Explore [Examples](EXAMPLES.md)
- Check [API Reference](API_REFERENCE.md)
