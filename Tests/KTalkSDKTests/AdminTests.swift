import Foundation
import OpenAPIRuntime
import Testing

@testable import KTalkSDK

@Suite("Admin")
struct AdminTests {
  private func client(_ transport: any ClientTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  @Test("calendarServer(id:) maps an undocumented 500 to serverError")
  func calendarServerError() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 500))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.calendarServer(id: "x")
    }
    guard case .serverError(let code, _) = error else {
      Issue.record("expected .serverError")
      return
    }
    #expect(code == 500)
  }

  @Test("applicationAccessInfo maps 403 to forbidden")
  func accessInfoForbidden() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 403))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.applicationAccessInfo()
    }
    guard case .forbidden = error else {
      Issue.record("expected .forbidden")
      return
    }
  }
}
