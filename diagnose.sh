#!/bin/bash

echo "🔍 SwiftCoderMCP Diagnostic Tool"
echo "================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# Function to check command
check_command() {
    if command -v "$1" &> /dev/null; then
        echo "${GREEN}✓${NC} $1: $(which $1)"
        return 0
    else
        echo "${RED}✗${NC} $1 not found"
        ((ERRORS++))
        return 1
    fi
}

# Function to check optional command without counting as an error
check_optional_command() {
    if command -v "$1" &> /dev/null; then
        echo "${GREEN}✓${NC} $1: $(which $1)"
        return 0
    else
        echo "${YELLOW}⚠${NC} $1 not found (optional)"
        ((WARNINGS++))
        return 1
    fi
}

# Function to check version
check_version() {
    local cmd="$1"
    local version_flag="${2:---version}"
    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd $version_flag 2>&1 | head -n 1)
        echo "  Version: $version"
    fi
}

echo "${BLUE}System Information:${NC}"
echo "  OS: $(uname -s)"
echo "  Architecture: $(uname -m)"
echo "  Date: $(date)"
echo ""

echo "${BLUE}Checking Prerequisites:${NC}"
check_command "swift"
check_version "swift"

check_command "git"
check_optional_command "xcodebuild"

echo ""
echo "${BLUE}Checking SwiftCoderMCP:${NC}"

# Check if installed
if command -v swift-coder-mcp &> /dev/null; then
    echo "${GREEN}✓${NC} swift-coder-mcp: $(which swift-coder-mcp)"
    swift-coder-mcp --version 2>/dev/null || echo "  (version check failed)"
else
    echo "${RED}✗${NC} swift-coder-mcp not in PATH"
    ((ERRORS++))
fi

# Check config directory
CONFIG_DIR="$HOME/.swift-coder-mcp"
if [ -d "$CONFIG_DIR" ]; then
    echo "${GREEN}✓${NC} Config directory: $CONFIG_DIR"
else
    echo "${YELLOW}⚠${NC} Config directory not found: $CONFIG_DIR"
    ((WARNINGS++))
fi

echo ""
echo "${BLUE}Checking Swift Installation:${NC}"

# Swift toolchain
if command -v swift &> /dev/null; then
    echo "  Toolchain: $(swift --version | head -n 1)"

    # Check for common issues
    if ! swift package --help &> /dev/null; then
        echo "${RED}✗${NC} Swift Package Manager not available"
        ((ERRORS++))
    else
        echo "${GREEN}✓${NC} Swift Package Manager available"
    fi
fi

echo ""
echo "${BLUE}Environment:${NC}"
echo "  PATH: $PATH"
echo "  HOME: $HOME"
echo "  SHELL: $SHELL"

echo ""
echo "${BLUE}Network Connectivity:${NC}"
if ping -c 1 github.com &> /dev/null; then
    echo "${GREEN}✓${NC} Can reach GitHub (needed for dependencies)"
else
    echo "${YELLOW}⚠${NC} Cannot reach GitHub"
    ((WARNINGS++))
fi

echo ""
echo "================================"
echo "${BLUE}Summary:${NC}"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "${GREEN}✅ All checks passed!${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo "${YELLOW}⚠️  $WARNINGS warning(s), no errors${NC}"
else
    echo "${RED}❌ $ERRORS error(s), $WARNINGS warning(s)${NC}"
fi

echo ""
echo "${BLUE}Quick Fixes:${NC}"
if [ $ERRORS -gt 0 ]; then
    echo "  • Install Swift: https://swift.org/download/"
    echo "  • Run install.sh to set up SwiftCoderMCP"
fi

if ! command -v swift-coder-mcp &> /dev/null; then
    echo "  • Add to PATH: export PATH="/usr/local/bin:\$PATH""
fi

echo ""
echo "For more help, visit: https://github.com/yourusername/SwiftCoderMCP"
