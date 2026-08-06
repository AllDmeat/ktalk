import Foundation
import Testing

@testable import KTalkSDK

@Suite("Error mapping")
struct ErrorMappingTests {
  private struct SampleError: Error {}

  private func makeClient() throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token")
  }

  @Test("Invalid or non-HTTPS base URLs are rejected")
  func rejectsInvalidBaseURL() {
    #expect(throws: KTalkError.self) {
      _ = try KTalkClient(baseURL: "http://example.ktalk.ru", token: "test-token")
    }
    #expect(throws: KTalkError.self) {
      _ = try KTalkClient(baseURL: "not a url", token: "test-token")
    }
  }

  @Test("statusError maps HTTP status codes to typed errors")
  func mapsStatusCodes() throws {
    let client = try makeClient()

    guard case .unauthorized = client.statusError(statusCode: 401, body: nil) else {
      Issue.record("401 should map to .unauthorized")
      return
    }
    guard case .forbidden = client.statusError(statusCode: 403, body: nil) else {
      Issue.record("403 should map to .forbidden")
      return
    }
    guard case .serverError(let code, _) = client.statusError(statusCode: 503, body: "boom") else {
      Issue.record("503 should map to .serverError")
      return
    }
    #expect(code == 503)
    guard case .unexpectedResponse(let other, _) = client.statusError(statusCode: 418, body: nil)
    else {
      Issue.record("418 should map to .unexpectedResponse")
      return
    }
    #expect(other == 418)
  }

  @Test("call rethrows KTalkError and wraps other failures as networkError")
  func callClassifiesErrors() async throws {
    let client = try makeClient()

    let rethrown = await #expect(throws: KTalkError.self) {
      try await client.call { throw KTalkError.forbidden }
    }
    guard case .forbidden = rethrown else {
      Issue.record("expected .forbidden to be rethrown unchanged")
      return
    }

    let wrapped = await #expect(throws: KTalkError.self) {
      try await client.call { throw SampleError() }
    }
    guard case .networkError = wrapped else {
      Issue.record("expected an unknown error to map to .networkError")
      return
    }
  }

  @Test("decode wraps failures as decodingError")
  func decodeWrapsFailures() throws {
    let client = try makeClient()
    let error = #expect(throws: KTalkError.self) {
      let _: Int = try client.decode { throw SampleError() }
    }
    guard case .decodingError = error else {
      Issue.record("expected .decodingError")
      return
    }
  }

  @Test("Synthetic fixtures load from the test bundle")
  func loadsSyntheticFixture() throws {
    let data = try ReplayTransport.fixtureData(named: "sample-recordings")
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(object?["nextPageToken"] as? String == "next-0002")
  }
}
