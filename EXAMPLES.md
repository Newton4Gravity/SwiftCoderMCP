# SwiftCoderMCP Examples

Real-world examples of using SwiftCoderMCP tools.

## Table of Contents
- [Project Creation](#project-creation)
- [Code Generation](#code-generation)
- [Package Management](#package-management)
- [Widget Development](#widget-development)
- [Macro Development](#macro-development)
- [Refactoring](#refactoring)
- [Scripting](#scripting)
- [Testing](#testing)

---

## Project Creation

### Example 1: Create a New iOS App with Widget

**User Prompt:**
> Create an iOS app called "WeatherWidget" with a home screen widget that shows current temperature and weather condition. Include location services and a settings screen.

**AI Actions:**
1. `scaffold_project` with template "ios-app"
2. `create_widget_extension` for weather widget
3. `generate_swiftui_view` for settings screen
4. `add_dependency` for location services

**Generated Structure:**
```
WeatherWidget/
├── WeatherWidget.app/
│   ├── Sources/
│   │   ├── WeatherWidgetApp.swift
│   │   ├── ContentView.swift
│   │   └── SettingsView.swift
│   └── WeatherWidgetWidget/
│       ├── Sources/
│       │   ├── WeatherWidget.swift
│       │   ├── WeatherProvider.swift
│       │   └── WeatherEntry.swift
│       └── Info.plist
└── Package.swift
```

### Example 2: Create a Swift CLI Tool

**User Prompt:**
> Create a CLI tool called "jsonvalidator" that validates JSON files. It should accept a file path argument, have a --pretty flag for formatted output, and return exit code 1 on validation errors.

**AI Actions:**
1. `create_cli_tool` with arguments and flags
2. `generate_struct` for validation results
3. `build_target` to compile

**Generated Code:**
```swift
import ArgumentParser
import Foundation

@main
struct JSONValidator: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "jsonvalidator",
        abstract: "Validate JSON files",
        version: "1.0.0"
    )

    @Argument(help: "Path to JSON file")
    var filePath: String

    @Flag(name: .shortAndLong, help: "Pretty print output")
    var pretty = false

    mutating func run() async throws {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)

        do {
            let json = try JSONSerialization.jsonObject(with: data)
            if pretty {
                let output = try JSONSerialization.data(
                    withJSONObject: json,
                    options: .prettyPrinted
                )
                print(String(data: output, encoding: .utf8)!)
            } else {
                print("✅ Valid JSON")
            }
        } catch {
            print("❌ Invalid JSON: \(error)")
            throw ExitCode.failure
        }
    }
}
```

---

## Code Generation

### Example 3: Generate Data Models

**User Prompt:**
> Generate a User struct with id (UUID), name (String), email (String, optional), createdAt (Date), and isActive (Bool, default true). Make it Codable and Equatable.

**AI Action:** `generate_struct`

**Generated Code:**
```swift
import Foundation

public struct User: Codable, Equatable {
    public let id: UUID
    public let name: String
    public let email: String?
    public let createdAt: Date
    public let isActive: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
        self.isActive = isActive
    }
}
```

### Example 4: Generate SwiftUI View with State

**User Prompt:**
> Generate a LoginView with email and password fields, a login button, and validation that enables the button only when both fields are non-empty.

**AI Action:** `generate_swiftui_view`

**Generated Code:**
```swift
import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: login) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Login")
                }
            }
            .disabled(!isValid || isLoading)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func login() {
        isLoading = true
        errorMessage = nil
        // Perform login
    }
}

#Preview {
    LoginView()
}
```

---

## Package Management

### Example 5: Add Multiple Dependencies

**User Prompt:**
> Add Alamofire 5.8.0, Kingfisher 7.0, and SwiftLint as a build tool to my project at ~/Projects/MyApp.

**AI Actions:**
1. `add_dependency` for Alamofire
2. `add_dependency` for Kingfisher
3. `add_dependency` for SwiftLint (plugin)

**Result:**
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire", from: "5.8.0"),
    .package(url: "https://github.com/onevcat/Kingfisher", from: "7.0.0"),
    .package(url: "https://github.com/realm/SwiftLint", from: "0.54.0"),
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "Alamofire", package: "Alamofire"),
            .product(name: "Kingfisher", package: "Kingfisher"),
        ],
        plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
    ),
]
```

### Example 6: Update All Dependencies

**User Prompt:**
> Check for outdated dependencies in my project and update them all to the latest compatible versions.

**AI Actions:**
1. `show_dependencies` to list current
2. `suggest_updates` to check for updates
3. `update_dependencies` to apply updates

**Result:**
```
Outdated Dependencies Found:
- Alamofire: 5.8.0 → 5.9.0 (minor)
- Kingfisher: 7.0.0 → 7.10.0 (minor)
- swift-syntax: 509.0.0 → 600.0.0 (major, breaking changes)

Updated:
✅ Alamofire 5.8.0 → 5.9.0
✅ Kingfisher 7.0.0 → 7.10.0
⚠️  swift-syntax 509.0.0 → 600.0.0 (review breaking changes)
```

---

## Widget Development

### Example 7: Create a Stock Price Widget

**User Prompt:**
> Create a widget that shows stock price for AAPL with current price, daily change percentage, and a mini chart. Update every 15 minutes.

**AI Action:** `create_widget_extension`

**Generated Structure:**
```swift
import WidgetKit
import SwiftUI
import Intents

struct StockEntry: TimelineEntry {
    let date: Date
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
}

struct StockProvider: TimelineProvider {
    func placeholder(in context: Context) -> StockEntry {
        StockEntry(
            date: Date(),
            symbol: "AAPL",
            price: 150.00,
            change: 2.50,
            changePercent: 1.67
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [StockEntry] = []
        let currentDate = Date()

        // Fetch stock data (simplified)
        for offset in 0..<4 {
            let entryDate = Calendar.current.date(
                byAdding: .minute,
                value: offset * 15,
                to: currentDate
            )!
            let entry = StockEntry(
                date: entryDate,
                symbol: "AAPL",
                price: 150.00 + Double.random(in: -5...5),
                change: 2.50,
                changePercent: 1.67
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct StockWidgetView: View {
    var entry: StockProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.symbol)
                    .font(.headline)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption)
            }

            Text("$\(String(format: "%.2f", entry.price))")
                .font(.title)
                .fontWeight(.bold)

            HStack(spacing: 4) {
                Image(systemName: entry.change >= 0 ? "arrow.up" : "arrow.down")
                Text("\(String(format: "%.2f", entry.change)) (\(String(format: "%.2f", entry.changePercent))%)")
            }
            .font(.caption)
            .foregroundColor(entry.change >= 0 ? .green : .red)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct StockWidget: Widget {
    let kind: String = "StockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StockProvider()) { entry in
            StockWidgetView(entry: entry)
        }
        .configurationDisplayName("Stock Price")
        .description("Shows current stock price for AAPL")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

---

## Macro Development

### Example 8: Create a URL Macro

**User Prompt:**
> Create a Swift macro that validates URLs at compile time. #url("https://example.com") should fail compilation if the URL is invalid.

**AI Action:** `create_macro_package`

**Generated Files:**

**URLValidator.swift** (Macro Declaration):
```swift
@freestanding(expression)
public macro url(_ stringLiteral: String) -> URL = #externalMacro(
    module: "URLValidatorMacros",
    type: "URLMacro"
)
```

**URLMacro.swift** (Implementation):
```swift
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

public struct URLMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression,
              let segments = argument.as(StringLiteralExprSyntax.self)?.segments,
              segments.count == 1,
              case .stringSegment(let literalSegment)? = segments.first else {
            throw MacroExpansionErrorMessage("#url requires a static string literal")
        }

        let urlString = literalSegment.content.text

        guard URL(string: urlString) != nil else {
            throw MacroExpansionErrorMessage("Invalid URL string: \(urlString)")
        }

        return "URL(string: \(argument))!"
    }
}

@main
struct URLValidatorPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [URLMacro.self]
}
```

**Usage:**
```swift
import URLValidator

// ✅ Compiles successfully
let validURL = #url("https://www.apple.com")

// ❌ Compilation error: Invalid URL string
let invalidURL = #url("not a valid url")
```

---

## Refactoring

### Example 9: Extract Method

**User Prompt:**
> Extract the networking code from lines 45-67 in NetworkManager.swift into a separate method called performRequest.

**AI Action:** `extract_method`

**Before:**
```swift
func fetchData() {
    let url = URL(string: "https://api.example.com/data")!
    let request = URLRequest(url: url)

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error)")
            return
        }

        guard let data = data else { return }

        do {
            let decoded = try JSONDecoder().decode([Item].self, from: data)
            self.items = decoded
        } catch {
            print("Decoding error: \(error)")
        }
    }
    task.resume()
}
```

**After:**
```swift
func fetchData() {
    performRequest()
}

private func performRequest() {
    let url = URL(string: "https://api.example.com/data")!
    let request = URLRequest(url: url)

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error)")
            return
        }

        guard let data = data else { return }

        do {
            let decoded = try JSONDecoder().decode([Item].self, from: data)
            self.items = decoded
        } catch {
            print("Decoding error: \(error)")
        }
    }
    task.resume()
}
```

### Example 10: Rename Symbol

**User Prompt:**
> Rename all instances of `userName` to `username` across my entire project.

**AI Action:** `rename_symbol`

**Result:**
```
Renamed 23 occurrences of 'userName' to 'username':
- Sources/Models/User.swift (3 occurrences)
- Sources/Views/ProfileView.swift (5 occurrences)
- Sources/ViewModels/ProfileViewModel.swift (8 occurrences)
- Tests/UserTests.swift (7 occurrences)
```

---

## Scripting

### Example 11: Create File Backup Script

**User Prompt:**
> Create a Swift script that backs up all .swift files from a source directory to a backup directory with timestamps.

**AI Action:** `create_swift_script`

**Generated Script:**
```swift
#!/usr/bin/env swift

import Foundation

// MARK: - Configuration
let sourceDir = CommandLine.arguments.dropFirst().first ?? "."
let backupDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Backups")
    .appendingPathComponent(Date().ISO8601Format())

// MARK: - Main
print("🔍 Scanning for .swift files in \(sourceDir)...")

let fileManager = FileManager.default
let sourceURL = URL(fileURLWithPath: sourceDir)

do {
    // Create backup directory
    try fileManager.createDirectory(
        at: backupDir,
        withIntermediateDirectories: true
    )

    // Find all .swift files
    let enumerator = fileManager.enumerator(
        at: sourceURL,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
    )

    var count = 0
    while let fileURL = enumerator?.nextObject() as? URL {
        if fileURL.pathExtension == "swift" {
            let relativePath = fileURL.path.replacingOccurrences(
                of: sourceURL.path + "/",
                with: ""
            )
            let backupFileURL = backupDir.appendingPathComponent(relativePath)

            // Create subdirectory if needed
            let backupSubdir = backupFileURL.deletingLastPathComponent()
            try fileManager.createDirectory(
                at: backupSubdir,
                withIntermediateDirectories: true
            )

            // Copy file
            try fileManager.copyItem(at: fileURL, to: backupFileURL)
            print("✅ Backed up: \(relativePath)")
            count += 1
        }
    }

    print("\n🎉 Backup complete! \(count) files backed up to:")
    print(backupDir.path)

} catch {
    print("❌ Error: \(error)")
    exit(1)
}
```

---

## Testing

### Example 12: Generate Comprehensive Tests

**User Prompt:**
> Generate comprehensive unit tests for my Calculator class that has add, subtract, multiply, divide, and power methods. Include edge cases like division by zero and overflow.

**AI Action:** `generate_unit_tests`

**Generated Tests:**
```swift
import Testing
@testable import Calculator

@Suite struct CalculatorTests {

    var calculator: Calculator!

    init() {
        calculator = Calculator()
    }

    // MARK: - Basic Operations

    @Test func addition() {
        #expect(calculator.add(2, 3) == 5)
        #expect(calculator.add(-1, 1) == 0)
        #expect(calculator.add(0, 0) == 0)
    }

    @Test func subtraction() {
        #expect(calculator.subtract(5, 3) == 2)
        #expect(calculator.subtract(1, 1) == 0)
        #expect(calculator.subtract(-1, -1) == 0)
    }

    @Test func multiplication() {
        #expect(calculator.multiply(2, 3) == 6)
        #expect(calculator.multiply(-2, 3) == -6)
        #expect(calculator.multiply(0, 100) == 0)
    }

    @Test func division() {
        #expect(calculator.divide(6, 3) == 2)
        #expect(calculator.divide(5, 2) == 2.5)
        #expect(calculator.divide(-6, 3) == -2)
    }

    @Test func power() {
        #expect(calculator.power(2, 3) == 8)
        #expect(calculator.power(5, 0) == 1)
        #expect(calculator.power(2, -1) == 0.5)
    }

    // MARK: - Edge Cases

    @Test func divisionByZero() {
        #expect(throws: CalculatorError.divisionByZero) {
            try calculator.divideSafe(5, 0)
        }
    }

    @Test func overflow() {
        let max = Int.max
        #expect(throws: CalculatorError.overflow) {
            try calculator.addSafe(max, 1)
        }
    }

    @Test func floatingPointPrecision() {
        let result = calculator.divide(1, 3)
        #expect(abs(result - 0.3333333333333333) < 0.0000000001)
    }
}
```

---

## Complex Workflows

### Example 13: Full App Development Workflow

**User Prompt:**
> I want to build a complete task management app called "TaskMaster" with:
> - iOS app with SwiftUI
> - Core Data persistence
> - Widget for home screen
> - Siri Shortcuts integration
> - Unit tests

**AI Workflow:**
1. `scaffold_project` - Create iOS app structure
2. `generate_struct` - Create Task model
3. `create_widget_extension` - Add widget
4. `create_shortcut_intent` - Add Siri integration
5. `generate_unit_tests` - Create tests
6. `build_target` - Build and verify

**Result:** Complete project with all requested features.

### Example 14: Library Development Workflow

**User Prompt:**
> Create a new Swift networking library "NetKit" with:
> - Async/await API
> - Request/response interceptors
> - Automatic retry logic
> - Comprehensive documentation
> - Example app

**AI Workflow:**
1. `create_swift_package` - Library package
2. `generate_protocol` - Define protocols
3. `generate_struct` - Create request/response types
4. `generate_unit_tests` - Test coverage
5. `scaffold_project` - Example app
6. `archive_build` - Create XCFramework

---

## Tips for Effective Prompts

### ✅ Good Prompts
- "Create an iOS app with SwiftUI using the ios-app template"
- "Generate a struct named User with id (UUID), name (String), email (String optional)"
- "Add Alamofire 5.8.0 to my project at ~/Projects/MyApp"
- "Create a widget that shows daily step count, updating every 15 minutes"

### ❌ Avoid These
- "Make an app" (too vague)
- "Create some code" (no specifics)
- "Add a library" (missing details)
- "Build something" (unclear scope)

---

More examples coming soon!
