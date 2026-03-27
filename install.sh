#!/bin/bash
set -e

echo "🚀 Installing SwiftCoderMCP..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="swift-coder-mcp"
CONFIG_DIR="$HOME/.swift-coder-mcp"

# Parse arguments
FORCE=false
BUILD_FROM_SOURCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE=true
            shift
            ;;
        --build|-b)
            BUILD_FROM_SOURCE=true
            shift
            ;;
        --prefix)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --force, -f          Force reinstall if already exists"
            echo "  --build, -b          Build from source instead of using prebuilt binary"
            echo "  --prefix PATH        Install to custom path (default: /usr/local/bin)"
            echo "  --help, -h           Show this help message"
            exit 0
            ;;
        *)
            echo "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Check if already installed
if [ -f "$INSTALL_DIR/$BINARY_NAME" ] && [ "$FORCE" = false ]; then
    echo "${YELLOW}⚠️  SwiftCoderMCP is already installed${NC}"
    echo "Use --force to reinstall, or run:"
    echo "  swift-coder-mcp --version"
    exit 0
fi

# Check for prebuilt binary or build
if [ "$BUILD_FROM_SOURCE" = true ]; then
    echo "${BLUE}🔨 Building from source...${NC}"
    if ! command -v swift &> /dev/null; then
        echo "${RED}❌ Swift is required to build from source${NC}"
        exit 1
    fi
    swift build -c release
    cp ".build/release/$BINARY_NAME" "$INSTALL_DIR/"
elif [ -f ".build/release/$BINARY_NAME" ]; then
    echo "${BLUE}📦 Using prebuilt binary...${NC}"
    cp ".build/release/$BINARY_NAME" "$INSTALL_DIR/"
elif [ -f "$BINARY_NAME" ]; then
    echo "${BLUE}📦 Using local binary...${NC}"
    cp "$BINARY_NAME" "$INSTALL_DIR/"
else
    echo "${RED}❌ No binary found. Please build first with: ./Scripts/build.sh${NC}"
    exit 1
fi

# Make executable
chmod +x "$INSTALL_DIR/$BINARY_NAME"

# Create config directory
mkdir -p "$CONFIG_DIR/templates"
mkdir -p "$CONFIG_DIR/snippets"

# Copy templates if they exist
if [ -d "Templates" ]; then
    echo "${BLUE}📁 Copying templates...${NC}"
    cp -r Templates/* "$CONFIG_DIR/templates/" 2>/dev/null || true
fi

# Create default config
cat > "$CONFIG_DIR/config.json" << EOF
{
    "version": "1.0.0",
    "defaultTemplatePath": "$CONFIG_DIR/templates",
    "defaultSnippetPath": "$CONFIG_DIR/snippets",
    "preferredTestFramework": "SwiftTesting",
    "codeStyle": "standard",
    "installed": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo "${GREEN}✅ SwiftCoderMCP installed successfully!${NC}"
echo ""
echo "📍 Location: $INSTALL_DIR/$BINARY_NAME"
echo "⚙️  Config: $CONFIG_DIR/"
echo ""
echo "Get started with:"
echo "  swift-coder-mcp --help"
echo ""

# Verify installation
if command -v "$BINARY_NAME" &> /dev/null; then
    echo "${GREEN}✓ Installation verified${NC}"
    "$BINARY_NAME" --version 2>/dev/null || echo "Version check skipped"
else
    echo "${YELLOW}⚠️  Installation directory not in PATH${NC}"
    echo "Add to your shell profile:"
    echo "  export PATH="$INSTALL_DIR:\$PATH""
fi
