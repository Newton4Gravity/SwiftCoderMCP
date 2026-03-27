import MCP
import Foundation

@main
struct SwiftCoderMCPServer {
    static func main() async throws {
        let server = Server(name: "swift-coder-mcp", version: "1.0.0")

        // Register all tool providers
        let providers: [ToolProvider] = [
            ProjectTools(),
            ScriptTools(),
            CodeGenTools(),
            PackageTools(),
            BuildTools(),
            TemplateTools(),
            WidgetTools(),
            ShortcutTools(),
            MacroTools(),
            DependencyTools(),
            TestTools(),
            RefactorTools(),
        ]

        for provider in providers {
            await server.register(provider)
        }

        // Start server with stdio transport
        let transport = StdioTransport()
        try await server.start(transport: transport)

        // Keep running
        RunLoop.main.run()
    }
}

// MARK: - Protocols

protocol ToolProvider {
    var tools: [Tool] { get }
    func handle(_ name: String, arguments: [String: Any]) async throws -> Any
}

extension Server {
    func register(_ provider: ToolProvider) async {
        for tool in provider.tools {
            await register(tool) { arguments in
                try await provider.handle(tool.name, arguments: arguments)
            }
        }
    }
}
