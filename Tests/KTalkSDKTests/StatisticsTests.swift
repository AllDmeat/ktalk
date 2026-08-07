import Foundation
import OpenAPIRuntime
import Testing

@testable import KTalkSDK

@Suite("Statistics")
struct StatisticsTests {
  private func client(_ transport: any ClientTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  @Test("onlineCounters decodes")
  func onlineDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "stats-online"))
    _ = try await client.onlineCounters()
  }

  @Test("domainStatistics maps 403 to forbidden")
  func statsForbidden() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 403))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.domainStatistics()
    }
    guard case .forbidden = error else {
      Issue.record("expected .forbidden, got \(String(describing: error))")
      return
    }
  }

  @Test("tariffExpirationDate decodes a nullable date")
  func tariffDecodes() async throws {
    let client = try client(
      ReplayTransport.returning(statusCode: 200, body: "\"2027-12-31T20:59:59Z\""))
    let date = try await client.tariffExpirationDate()
    #expect(date != nil)
  }
}
