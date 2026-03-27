import MCP
import Foundation

// MARK: - Widget Tools

struct WidgetTools: ToolProvider {
    var tools: [Tool] {
        [
            Tool(
                name: "create_widget_extension",
                description: "Create a complete WidgetKit extension with TimelineProvider and SwiftUI views",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "appPath": ["type": "string", "description": "Path to existing iOS/macOS app"],
                        "widgetKind": ["type": "string", "description": "Unique identifier for widget"],
                        "supportedFamilies": [
                            "type": "array",
                            "items": [
                                "type": "string",
                                "enum": ["systemSmall", "systemMedium", "systemLarge", "systemExtraLarge", "accessoryCircular", "accessoryRectangular", "accessoryInline"]
                            ],
                            "default": ["systemSmall", "systemMedium", "systemLarge"]
                        ],
                        "refreshInterval": ["type": "integer", "description": "Minutes between updates", "default": 15],
                        "includeLiveActivity": ["type": "boolean", "default": false],
                        "includeConfiguration": ["type": "boolean", "default": false]
                    ],
                    "required": ["name", "appPath"]
                ]
            ),
            Tool(
                name: "create_intent_configuration",
                description: "Create AppIntent-based configurable widget with user-customizable parameters",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "widgetName": ["type": "string"],
                        "parameters": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "type": ["type": "string"],
                                    "title": ["type": "string"],
                                    "description": ["type": "string"],
                                    "defaultValue": ["type": "any"]
                                ]
                            ]
                        ]
                    ],
                    "required": ["widgetName", "parameters"]
                ]
            ),
            Tool(
                name: "create_live_activity",
                description: "Create Live Activity for Dynamic Island and Lock Screen",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "attributes": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "type": ["type": "string"]
                                ]
                            ]
                        ],
                        "states": [
                            "type": "array",
                            "items": [
                                "type": "string",
                                "enum": ["compactLeading", "compactTrailing", "minimal", "expanded"]
                            ]
                        ]
                    ],
                    "required": ["name"]
                ]
            ),
            Tool(
                name: "generate_widget_preview",
                description: "Generate Xcode preview code for widget families",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "widgetName": ["type": "string"],
                        "families": ["type": "array", "items": ["type": "string"]],
                        "sampleData": ["type": "object"]
                    ],
                    "required": ["widgetName"]
                ]
            ),
            Tool(
                name: "create_app_clip",
                description: "Create App Clip target with associated domains and invocation URLs",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "appPath": ["type": "string"],
                        "clipName": ["type": "string"],
                        "invocationURLs": ["type": "array", "items": ["type": "string"]],
                        "maxSizeMB": ["type": "integer", "default": 15]
                    ],
                    "required": ["appPath", "clipName"]
                ]
            ),
        ]
    }

    func handle(_ name: String, arguments: [String: Any]) async throws -> Any {
        switch name {
        case "create_widget_extension":
            return try await createWidgetExtension(arguments)
        case "create_intent_configuration":
            return try await createIntentConfiguration(arguments)
        case "create_live_activity":
            return try await createLiveActivity(arguments)
        case "generate_widget_preview":
            return try await generateWidgetPreview(arguments)
        case "create_app_clip":
            return try await createAppClip(arguments)
        default:
            throw MCPError.methodNotFound
        }
    }

    // MARK: - Implementation

    private func createWidgetExtension(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String,
              let appPath = args["appPath"] as? String else {
            throw MCPError.invalidParams
        }

        let widgetKind = args["widgetKind"] as? String ?? "com.example.\(name.lowercased())"
        let supportedFamilies = args["supportedFamilies"] as? [String] ?? ["systemSmall", "systemMedium", "systemLarge"]
        let refreshInterval = args["refreshInterval"] as? Int ?? 15
        let includeLiveActivity = args["includeLiveActivity"] as? Bool ?? false
        let includeConfiguration = args["includeConfiguration"] as? Bool ?? false

        let widgetPath = URL(fileURLWithPath: appPath).appendingPathComponent("\(name)Widget")
        let sourcesPath = widgetPath.appendingPathComponent("Sources")

        // Create directories
        try FileManager.default.createDirectory(at: sourcesPath, withIntermediateDirectories: true)

        // Generate TimelineEntry
        let entryContent = """
        import WidgetKit
        import SwiftUI

        struct \(name)Entry: TimelineEntry {
            let date: Date
            let value: String
            let status: String

            static var placeholder: \(name)Entry {
                \(name)Entry(date: Date(), value: "--", status: "Loading...")
            }

            static var sample: \(name)Entry {
                \(name)Entry(date: Date(), value: "42", status: "Active")
            }
        }
        """

        let entryPath = sourcesPath.appendingPathComponent("\(name)Entry.swift")
        try entryContent.write(to: entryPath, atomically: true, encoding: .utf8)

        // Generate TimelineProvider
        let providerContent = """
        import WidgetKit
        import SwiftUI

        struct \(name)Provider: TimelineProvider {
            func placeholder(in context: Context) -> \(name)Entry {
                \(name)Entry.placeholder
            }

            func getSnapshot(in context: Context, completion: @escaping (\(name)Entry) -> ()) {
                completion(\(name)Entry.sample)
            }

            func getTimeline(in context: Context, completion: @escaping (Timeline<\(name)Entry>) -> ()) {
                var entries: [\(name)Entry] = []
                let currentDate = Date()

                for offset in 0..<5 {
                    let entryDate = Calendar.current.date(byAdding: .minute, value: offset * \(refreshInterval), to: currentDate)!
                    let entry = \(name)Entry(
                        date: entryDate,
                        value: "Value \(offset)",
                        status: "Status \(offset)"
                    )
                    entries.append(entry)
                }

                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
            }
        }
        """

        let providerPath = sourcesPath.appendingPathComponent("\(name)Provider.swift")
        try providerContent.write(to: providerPath, atomically: true, encoding: .utf8)

        // Generate Widget View
        let widgetViewContent = """
        import WidgetKit
        import SwiftUI

        struct \(name)WidgetView: View {
            var entry: \(name)Provider.Entry
            @Environment(\.widgetFamily) var family

            var body: some View {
                switch family {
                case .systemSmall:
                    smallView
                case .systemMedium:
                    mediumView
                case .systemLarge:
                    largeView
                default:
                    smallView
                }
            }

            private var smallView: some View {
                VStack {
                    Text(entry.value)
                        .font(.largeTitle)
                    Text(entry.status)
                        .font(.caption)
                }
                .containerBackground(.fill.tertiary, for: .widget)
            }

            private var mediumView: some View {
                HStack {
                    VStack {
                        Text(entry.value)
                            .font(.title)
                        Text(entry.status)
                            .font(.caption)
                    }
                    Spacer()
                    Text(entry.date, style: .time)
                }
                .padding()
                .containerBackground(.fill.tertiary, for: .widget)
            }

            private var largeView: some View {
                VStack {
                    Text(entry.value)
                        .font(.system(size: 48, weight: .bold))
                    Text(entry.status)
                        .font(.title2)
                    Text(entry.date, style: .date)
                        .font(.caption)
                }
                .containerBackground(.fill.tertiary, for: .widget)
            }
        }
        """

        let widgetViewPath = sourcesPath.appendingPathComponent("\(name)WidgetView.swift")
        try widgetViewContent.write(to: widgetViewPath, atomically: true, encoding: .utf8)

        // Generate Widget Configuration
        var widgetConfigContent = """
        import WidgetKit
        import SwiftUI

        @main
        struct \(name)Widget: Widget {
            let kind: String = "\(widgetKind)"

            var body: some WidgetConfiguration {
        """

        if includeConfiguration {
            widgetConfigContent += """
                AppIntentConfiguration(
                    kind: kind,
                    intent: \(name)ConfigurationIntent.self,
                    provider: \(name)Provider()
                ) { entry in
                    \(name)WidgetView(entry: entry)
                }
            """
        } else {
            widgetConfigContent += """
                StaticConfiguration(
                    kind: kind,
                    provider: \(name)Provider()
                ) { entry in
                    \(name)WidgetView(entry: entry)
                }
            """
        }

        widgetConfigContent += """
                .configurationDisplayName("\(name)")
                .description("A widget created with SwiftCoderMCP")
                .supportedFamilies([\(supportedFamilies.map { ".\($0)" }.joined(separator: ", "))])
            }
        }
        """

        let widgetConfigPath = sourcesPath.appendingPathComponent("\(name)Widget.swift")
        try widgetConfigContent.write(to: widgetConfigPath, atomically: true, encoding: .utf8)

        // Generate Preview code
        let previewContent = """
        #Preview(as: .systemSmall) {
            \(name)Widget()
        } timeline: {
            \(name)Entry(date: .now, value: "Preview 1", status: "Active")
            \(name)Entry(date: .now.addingTimeInterval(3600), value: "Preview 2", status: "Standby")
        }

        #Preview(as: .systemMedium) {
            \(name)Widget()
        } timeline: {
            \(name)Entry(date: .now, value: "Preview 1", status: "Active")
        }

        #Preview(as: .systemLarge) {
            \(name)Widget()
        } timeline: {
            \(name)Entry(date: .now, value: "Preview 1", status: "Active")
        }
        """

        let previewPath = sourcesPath.appendingPathComponent("Previews.swift")
        try previewContent.write(to: previewPath, atomically: true, encoding: .utf8)

        // Generate Info.plist
        let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleDevelopmentRegion</key>
            <string>$(DEVELOPMENT_LANGUAGE)</string>
            <key>CFBundleDisplayName</key>
            <string>\(name)</string>
            <key>CFBundleExecutable</key>
            <string>$(EXECUTABLE_NAME)</string>
            <key>CFBundleIdentifier</key>
            <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundleName</key>
            <string>$(PRODUCT_NAME)</string>
            <key>CFBundlePackageType</key>
            <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundleVersion</key>
            <string>1</string>
            <key>NSExtension</key>
            <dict>
                <key>NSExtensionPointIdentifier</key>
                <string>com.apple.widgetkit-extension</string>
            </dict>
        </dict>
        </plist>
        """

        let infoPlistPath = widgetPath.appendingPathComponent("Info.plist")
        try infoPlist.write(to: infoPlistPath, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "widgetName": name,
            "path": widgetPath.path,
            "filesCreated": [
                entryPath.lastPathComponent,
                providerPath.lastPathComponent,
                widgetViewPath.lastPathComponent,
                widgetConfigPath.lastPathComponent,
                previewPath.lastPathComponent,
                infoPlistPath.lastPathComponent
            ],
            "supportedFamilies": supportedFamilies,
            "refreshInterval": refreshInterval,
            "includeConfiguration": includeConfiguration,
            "includeLiveActivity": includeLiveActivity
        ]
    }

    private func createIntentConfiguration(_ args: [String: Any]) async throws -> Any {
        guard let widgetName = args["widgetName"] as? String,
              let parameters = args["parameters"] as? [[String: Any]] else {
            throw MCPError.invalidParams
        }

        var intentContent = """
        import AppIntents
        import WidgetKit

        struct \(widgetName)ConfigurationIntent: WidgetConfigurationIntent {
            static var title: LocalizedStringResource = "\(widgetName) Configuration"
            static var description = IntentDescription("Configure your \(widgetName) widget")

        """

        for param in parameters {
            guard let name = param["name"] as? String,
                  let type = param["type"] as? String else { continue }

            let title = param["title"] as? String ?? name.capitalized
            let description = param["description"] as? String ?? ""
            let defaultValue = param["defaultValue"]

            intentContent += """

            @Parameter(title: "\(title)", default: \(defaultValue != nil ? "\(defaultValue!)" : "nil"))
            var \(name): \(type)?
            """
        }

        intentContent += "
}"

        return [
            "success": true,
            "code": intentContent,
            "widgetName": widgetName,
            "parameters": parameters.count
        ]
    }

    private func createLiveActivity(_ args: [String: Any]) async throws -> Any {
        guard let name = args["name"] as? String else {
            throw MCPError.invalidParams
        }

        let attributes = args["attributes"] as? [[String: String]] ?? []
        let states = args["states"] as? [String] ?? ["compactLeading", "compactTrailing", "expanded"]

        // Generate ActivityAttributes
        var attributesContent = """
        import ActivityKit
        import SwiftUI

        struct \(name)Attributes: ActivityAttributes {
            public struct ContentState: Codable, Hashable {
        """

        for attr in attributes {
            if let attrName = attr["name"], let attrType = attr["type"] {
                attributesContent += "
		var \(attrName): \(attrType)"
            }
        }

        attributesContent += """

            }

        """

        for attr in attributes {
            if let attrName = attr["name"], let attrType = attr["type"] {
                attributesContent += "
	var \(attrName): \(attrType)"
            }
        }

        attributesContent += "
}"

        // Generate Live Activity View
        var activityViewContent = """
        import ActivityKit
        import SwiftUI

        struct \(name)LiveActivity: Widget {
            var body: some WidgetConfiguration {
                ActivityConfiguration(for: \(name)Attributes.self) { context in
                    // Lock Screen / Notification Center
                    LockScreenView(context: context)
                } dynamicIsland: { context in
                    DynamicIsland {
        """

        if states.contains("expanded") {
            activityViewContent += """
                        // Expanded
                        DynamicIslandExpandedRegion(.leading) {
                            Text(context.state.status)
                                .font(.title2)
                        }
                        DynamicIslandExpandedRegion(.trailing) {
                            Text(context.state.value)
                                .font(.title2)
                        }
                        DynamicIslandExpandedRegion(.bottom) {
                            Text(context.attributes.title)
                                .font(.caption)
                        }
            """
        }

        activityViewContent += """
                    } compactLeading: {
        """

        if states.contains("compactLeading") {
            activityViewContent += """
                        Text(context.state.status)
            """
        }

        activityViewContent += """
                    } compactTrailing: {
        """

        if states.contains("compactTrailing") {
            activityViewContent += """
                        Text(context.state.value)
            """
        }

        activityViewContent += """
                    } minimal: {
        """

        if states.contains("minimal") {
            activityViewContent += """
                        Image(systemName: "bell")
            """
        }

        activityViewContent += """
                    }
                }
            }
        }

        struct LockScreenView: View {
            let context: ActivityViewContext<\(name)Attributes>

            var body: some View {
                VStack {
                    Text(context.attributes.title)
                        .font(.headline)
                    HStack {
                        Text(context.state.status)
                        Spacer()
                        Text(context.state.value)
                    }
                }
                .padding()
                .activityBackgroundTint(Color.cyan.opacity(0.2))
                .activitySystemActionForegroundColor(Color.black)
            }
        }
        """

        return [
            "success": true,
            "attributesCode": attributesContent,
            "liveActivityCode": activityViewContent,
            "activityName": name,
            "supportedStates": states
        ]
    }

    private func generateWidgetPreview(_ args: [String: Any]) async throws -> Any {
        guard let widgetName = args["widgetName"] as? String else {
            throw MCPError.invalidParams
        }

        let families = args["families"] as? [String] ?? ["systemSmall", "systemMedium", "systemLarge"]
        let sampleData = args["sampleData"] as? [String: String] ?? [:]

        var previewCode = ""

        for family in families {
            previewCode += """
            #Preview(as: .\(family)) {
                \(widgetName)Widget()
            } timeline: {
                \(widgetName)Entry(date: .now, value: "\(sampleData["value"] ?? "Preview")", status: "\(sampleData["status"] ?? "Active")")
                \(widgetName)Entry(date: .now.addingTimeInterval(3600), value: "Updated", status: "Changed")
            }

            """
        }

        return [
            "success": true,
            "code": previewCode,
            "widgetName": widgetName,
            "families": families
        ]
    }

    private func createAppClip(_ args: [String: Any]) async throws -> Any {
        guard let appPath = args["appPath"] as? String,
              let clipName = args["clipName"] as? String else {
            throw MCPError.invalidParams
        }

        let invocationURLs = args["invocationURLs"] as? [String] ?? []
        let maxSizeMB = args["maxSizeMB"] as? Int ?? 15

        let clipPath = URL(fileURLWithPath: appPath).appendingPathComponent("\(clipName)Clip")

        // Create directory structure
        let directories = ["Sources", "Resources", "Entitlements"]
        for dir in directories {
            let dirPath = clipPath.appendingPathComponent(dir)
            try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)
        }

        // Generate App Clip entry point
        let clipContent = """
        import SwiftUI

        @main
        struct \(clipName)ClipApp: App {
            @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

            var body: some Scene {
                WindowGroup {
                    ContentView()
                        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                            guard let url = userActivity.webpageURL else { return }
                            handleInvocationURL(url)
                        }
                }
            }

            func handleInvocationURL(_ url: URL) {
                // Handle the invocation URL
                print("Received invocation URL: \(url)")
            }
        }

        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("\(clipName) App Clip")
                        .font(.largeTitle)
                    Text("Lightweight app experience")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }

        class AppDelegate: NSObject, UIApplicationDelegate {
            func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
                return true
            }

            func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
                guard let url = userActivity.webpageURL else { return false }
                // Handle URL
                return true
            }
        }
        """

        let clipSourcePath = clipPath.appendingPathComponent("Sources/\(clipName)ClipApp.swift")
        try clipContent.write(to: clipSourcePath, atomically: true, encoding: .utf8)

        // Generate Entitlements
        let entitlements = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>com.apple.developer.parent-application-identifiers</key>
            <array>
                <string>$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)</string>
            </array>
            <key>com.apple.developer.on-demand-install-capable</key>
            <true/>
        </dict>
        </plist>
        """

        let entitlementsPath = clipPath.appendingPathComponent("Entitlements/\(clipName)Clip.entitlements")
        try entitlements.write(to: entitlementsPath, atomically: true, encoding: .utf8)

        // Generate associated domains file
        var associatedDomains = "{
  "applinks": [
"
        for (index, url) in invocationURLs.enumerated() {
            let comma = index < invocationURLs.count - 1 ? "," : ""
            associatedDomains += "    "\(url)"\(comma)
"
        }
        associatedDomains += "  ]
}"

        let associatedDomainsPath = clipPath.appendingPathComponent("Resources/apple-app-site-association")
        try associatedDomains.write(to: associatedDomainsPath, atomically: true, encoding: .utf8)

        return [
            "success": true,
            "clipName": clipName,
            "path": clipPath.path,
            "maxSizeMB": maxSizeMB,
            "invocationURLs": invocationURLs,
            "filesCreated": [
                clipSourcePath.lastPathComponent,
                entitlementsPath.lastPathComponent,
                associatedDomainsPath.lastPathComponent
            ]
        ]
    }
}
