import Foundation
import OpenAPIRuntime
import Testing

@testable import KTalkSDK

@Suite("Kiosks")
struct KiosksTests {
  private func client(_ transport: any ClientTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  @Test("kiosk(id:) maps 404 to notFound")
  func getNotFound() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 404))
    let error = await #expect(throws: KTalkError.self) { _ = try await client.kiosk(id: "gone") }
    guard case .notFound(let resource, _) = error else {
      Issue.record("expected .notFound")
      return
    }
    #expect(resource == "kiosk")
  }

  @Test("deleteKiosk maps 403 to forbidden")
  func deleteForbidden() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 403))
    let error = await #expect(throws: KTalkError.self) { try await client.deleteKiosk(id: "k-1") }
    guard case .forbidden = error else {
      Issue.record("expected .forbidden")
      return
    }
  }
}
