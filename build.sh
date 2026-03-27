#!/bin/bash
set -e

echo "🔨 Building SwiftCoderMCP..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Swift is installed
if ! command -v swift &> /dev/null; then
    echo "${RED}❌ Swift is not installed${NC}"
    echo "Please install Swift from https://swift.org/download/"
    exit 1
fi

# Check Swift version
SWIFT_VERSION=$(swift --version | head -n 1)
echo "${GREEN}✓ Found: $SWIFT_VERSION${NC}"

# Build the project
echo "${YELLOW}📦 Building package...${NC}"
swift build -c release

if [ $? -eq 0 ]; then
    echo "${GREEN}✅ Build successful!${NC}"
    echo ""
    echo "Binary location: .build/release/swift-coder-mcp"
    echo ""
    echo "To install system-wide, run:"
    echo "  sudo cp .build/release/swift-coder-mcp /usr/local/bin/"
else
    echo "${RED}❌ Build failed${NC}"
    exit 1
fi

# Run tests if requested
if [ "$1" == "--test" ] || [ "$1" == "-t" ]; then
    echo "${YELLOW}🧪 Running tests...${NC}"
    swift test
fi

# Create install package if requested
if [ "$1" == "--package" ] || [ "$1" == "-p" ]; then
    echo "${YELLOW}📦 Creating distribution package...${NC}"

    VERSION=$(git describe --tags --always 2>/dev/null || echo "1.0.0")
    PACKAGE_DIR="swift-coder-mcp-$VERSION"

    mkdir -p "$PACKAGE_DIR"
    cp .build/release/swift-coder-mcp "$PACKAGE_DIR/"
    cp README.md "$PACKAGE_DIR/" 2>/dev/null || echo "No README.md"
    cp LICENSE "$PACKAGE_DIR/" 2>/dev/null || echo "No LICENSE"

    # Create install script
    cat > "$PACKAGE_DIR/install.sh" << 'EOF'
#!/bin/bash
set -e

echo "Installing SwiftCoderMCP..."
sudo cp swift-coder-mcp /usr/local/bin/
echo "✅ Installation complete!"
echo "Run 'swift-coder-mcp --help' to get started"
EOF
    chmod +x "$PACKAGE_DIR/install.sh"

    tar -czf "$PACKAGE_DIR.tar.gz" "$PACKAGE_DIR"
    rm -rf "$PACKAGE_DIR"

    echo "${GREEN}✅ Package created: $PACKAGE_DIR.tar.gz${NC}"
fi

echo ""
echo "${GREEN}🎉 Done!${NC}"
