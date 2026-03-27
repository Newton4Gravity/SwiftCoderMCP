# SwiftCoderMCP Makefile

.PHONY: build test install clean release lint format help

# Default target
.DEFAULT_GOAL := help

# Variables
BINARY_NAME = swift-coder-mcp
BUILD_DIR = .build
RELEASE_DIR = releases
PREFIX = /usr/local/bin

# Colors
BLUE = [0;34m
GREEN = [0;32m
YELLOW = [1;33m
RED = [0;31m
NC = [0m # No Color

help: ## Show this help message
	@echo "$(BLUE)SwiftCoderMCP - Available Commands:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s
", $$1, $$2}'

build: ## Build the project in release mode
	@echo "$(BLUE)🔨 Building $(BINARY_NAME)...$(NC)"
	swift build -c release
	@echo "$(GREEN)✅ Build complete!$(NC)"

test: ## Run tests
	@echo "$(BLUE)🧪 Running tests...$(NC)"
	swift test
	@echo "$(GREEN)✅ Tests complete!$(NC)"

install: build ## Install binary to system (requires sudo)
	@echo "$(BLUE)📦 Installing $(BINARY_NAME) to $(PREFIX)...$(NC)"
	@cp $(BUILD_DIR)/release/$(BINARY_NAME) $(PREFIX)/
	@chmod +x $(PREFIX)/$(BINARY_NAME)
	@echo "$(GREEN)✅ Installation complete!$(NC)"
	@echo "Run '$(BINARY_NAME) --help' to get started"

uninstall: ## Uninstall binary from system
	@echo "$(YELLOW)🗑️  Removing $(BINARY_NAME) from $(PREFIX)...$(NC)"
	@rm -f $(PREFIX)/$(BINARY_NAME)
	@echo "$(GREEN)✅ Uninstalled!$(NC)"

clean: ## Clean build artifacts
	@echo "$(BLUE)🧹 Cleaning build artifacts...$(NC)"
	swift package clean
	@rm -rf $(BUILD_DIR)
	@rm -rf $(RELEASE_DIR)
	@echo "$(GREEN)✅ Clean complete!$(NC)"

release: clean build ## Create a release package
	@echo "$(BLUE)📦 Creating release package...$(NC)"
	@mkdir -p $(RELEASE_DIR)
	@cp $(BUILD_DIR)/release/$(BINARY_NAME) $(RELEASE_DIR)/
	@cp README.md $(RELEASE_DIR)/ 2>/dev/null || true
	@cp LICENSE $(RELEASE_DIR)/ 2>/dev/null || true
	@cp -r Scripts $(RELEASE_DIR)/
	@cp -r Documentation $(RELEASE_DIR)/
	@cd $(RELEASE_DIR) && tar -czf $(BINARY_NAME)-$(shell git describe --tags --always 2>/dev/null || echo "1.0.0").tar.gz *
	@echo "$(GREEN)✅ Release package created in $(RELEASE_DIR)/$(NC)"

lint: ## Run SwiftLint
	@echo "$(BLUE)🔍 Running SwiftLint...$(NC)"
	@swiftlint lint --quiet 2>/dev/null || echo "$(YELLOW)⚠️  SwiftLint not installed$(NC)"

format: ## Format code with swift-format
	@echo "$(BLUE)✨ Formatting code...$(NC)"
	@swift-format -i -r Sources/
	@echo "$(GREEN)✅ Formatting complete!$(NC)"

dev-setup: ## Setup development environment
	@echo "$(BLUE)⚙️  Setting up development environment...$(NC)"
	@mkdir -p Templates Script CommandLineTool WidgetExtension SwiftPackage iOSApp macOSApp SwiftMacro
	@echo "$(GREEN)✅ Development environment ready!$(NC)"

diagnose: ## Run diagnostic checks
	@echo "$(BLUE)🔍 Running diagnostics...$(NC)"
	@./Scripts/diagnose.sh

update-deps: ## Update dependencies
	@echo "$(BLUE)📦 Updating dependencies...$(NC)"
	swift package update
	@echo "$(GREEN)✅ Dependencies updated!$(NC)"

resolve-deps: ## Resolve dependencies
	@echo "$(BLUE)📦 Resolving dependencies...$(NC)"
	swift package resolve
	@echo "$(GREEN)✅ Dependencies resolved!$(NC)"

# Docker targets (optional)
docker-build: ## Build Docker image
	@echo "$(BLUE)🐳 Building Docker image...$(NC)"
	@docker build -t $(BINARY_NAME):latest .

docker-run: ## Run Docker container
	@echo "$(BLUE)🐳 Running Docker container...$(NC)"
	@docker run -it --rm $(BINARY_NAME):latest
