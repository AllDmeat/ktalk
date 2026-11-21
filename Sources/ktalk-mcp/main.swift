import Foundation
import KTalkSDK
import MCP

let server = Server(
  name: "ktalk-mcp",
  version: KTalkSDK.version,
  capabilities: .init(tools: .init(listChanged: false))
)

await server.withMethodHandler(ListTools.self) { _ in .init(tools: tools) }
await server.withMethodHandler(CallTool.self) { params in
  await handle(
    params, makeClient: { try makeClient(environment: ProcessInfo.processInfo.environment) })
}

try await server.start(transport: StdioTransport())
await server.waitUntilCompleted()
