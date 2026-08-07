import Foundation
import OpenAPIRuntime
import Testing

@testable import KTalkSDK

@Suite("Reporting")
struct ReportingTests {
  private func client(_ transport: any ClientTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  @Test("conference(key:) decodes a conference")
  func conferenceDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "conference"))
    _ = try await client.conference(key: "conf-1")
  }

  @Test("conference(key:) maps the documented 404 to notFound")
  func conferenceNotFound() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 404))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.conference(key: "gone")
    }
    guard case .notFound(let resource, _) = error else {
      Issue.record("expected .notFound, got \(String(describing: error))")
      return
    }
    #expect(resource == "conference")
  }

  @Test("conference(key:) maps 500 to serverError")
  func conferenceServerError() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 500))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.conference(key: "conf-1")
    }
    guard case .serverError(let code, _) = error else {
      Issue.record("expected .serverError, got \(String(describing: error))")
      return
    }
    #expect(code == 500)
  }

  @Test("conferences(list) maps an undocumented 403 to forbidden")
  func conferencesForbidden() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 403))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.conferences()
    }
    guard case .forbidden = error else {
      Issue.record("expected .forbidden, got \(String(describing: error))")
      return
    }
  }
}
