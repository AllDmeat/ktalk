import Foundation
import OpenAPIRuntime
import Testing

@testable import KTalkSDK

@Suite("Webhooks")
struct WebhooksTests {
  private func client(_ transport: any ClientTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  @Test("listWebhooks decodes an array")
  func listDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "webhooks-list"))
    let hooks = try await client.listWebhooks()
    #expect(hooks.count == 1)
  }

  @Test("deleteWebhook succeeds on 200 and maps 404")
  func delete() async throws {
    let ok = try client(ReplayTransport.returning(statusCode: 200))
    try await ok.deleteWebhook(webhookKey: "wh-1")
    let missing = try client(ReplayTransport.returning(statusCode: 404))
    let error = await #expect(throws: KTalkError.self) {
      try await missing.deleteWebhook(webhookKey: "gone")
    }
    guard case .notFound(let resource, _) = error else {
      Issue.record("expected .notFound, got \(String(describing: error))")
      return
    }
    #expect(resource == "webhook")
  }
}
