import Foundation
import MCP
import Testing

@testable import KTalkSDK
@testable import ktalk_mcp

@Suite("MCP server")
struct MCPServerTests {
  private func client(_ transport: ReplayTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  @Test("every tool is read-only and has a unique name")
  func toolsAreReadOnly() {
    #expect(Set(tools.map(\.name)).count == tools.count)
    #expect(tools.allSatisfy { $0.annotations.readOnlyHint == true })
  }

  @Test("a tool returns the SDK result as JSON")
  func getRecordingReturnsJSON() async throws {
    let client = try client(try ReplayTransport.fixture(named: "accessible-recording"))
    let params = CallTool.Parameters(name: "ktalk_get_recording", arguments: ["key": "rec-1"])
    let result = await handle(params, makeClient: { client })
    #expect(result.isError == false)
    guard case .text(let text, _, _) = result.content.first else {
      Issue.record("expected text content")
      return
    }
    #expect(text.contains("Synthetic standup"))
  }

  @Test("a missing argument and an unknown tool are errors, not crashes")
  func errorsAreReported() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 200))
    let missing = await handle(.init(name: "ktalk_get_recording"), makeClient: { client })
    #expect(missing.isError == true)
    let unknown = await handle(.init(name: "ktalk_delete_everything"), makeClient: { client })
    #expect(unknown.isError == true)
  }

  @Test("an API error is returned as an error result")
  func apiErrorIsReported() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 403))
    let params = CallTool.Parameters(name: "ktalk_get_summary", arguments: ["key": "rec-1"])
    let result = await handle(params, makeClient: { client })
    #expect(result.isError == true)
  }

  @Test("missing environment names the variable")
  func missingEnvironment() {
    #expect(throws: ToolError.self) { try makeClient(environment: [:]) }
    #expect(throws: ToolError.self) {
      try makeClient(environment: ["KTALK_BASE_URL": "https://example.ktalk.ru"])
    }
  }

  @Test("dates accept a bare day and a date-time")
  func dates() throws {
    #expect(try date("2026-01-02") == date("2026-01-02T00:00:00Z"))
    #expect(throws: ToolError.self) { try date("yesterday") }
  }
}
