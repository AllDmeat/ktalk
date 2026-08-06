import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import KTalkSDK

@Suite("Recordings")
struct RecordingsTests {
  private func client(_ transport: any ClientTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  @Test("listRecordings decodes a page and its cursor")
  func listDecodesPage() async throws {
    let client = try client(try ReplayTransport.fixture(named: "recordings-list"))
    let page = try await client.listRecordings(limit: 10)
    #expect(page.items.count == 1)
    #expect(page.items.first?.key == "rec-1")
    #expect(page.nextPageToken == "page-2")
    #expect(page.hasNextPage)
  }

  @Test("recording(key:) decodes a single recording, incl. a non-fractional timestamp")
  func getDecodesRecording() async throws {
    let client = try client(try ReplayTransport.fixture(named: "recording"))
    let recording = try await client.recording(key: "rec-1")
    #expect(recording.key == "rec-1")
    #expect(recording.title == "Synthetic standup")
  }

  @Test("recording(key:) maps 404 to notFound")
  func getMapsNotFound() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 404))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.recording(key: "missing")
    }
    guard case .notFound(let resource, let identifier) = error else {
      Issue.record("expected .notFound, got \(String(describing: error))")
      return
    }
    #expect(resource == "recording")
    #expect(identifier == "missing")
  }

  @Test("recording(key:) maps 403 to forbidden")
  func getMapsForbidden() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 403))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.recording(key: "rec-1")
    }
    guard case .forbidden = error else {
      Issue.record("expected .forbidden, got \(String(describing: error))")
      return
    }
  }

  @Test("recordingTranscript(key:) decodes")
  func transcriptDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "transcript"))
    _ = try await client.recordingTranscript(key: "rec-1")
  }

  @Test("recordingSummary(key:) decodes")
  func summaryDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "summary"))
    _ = try await client.recordingSummary(key: "rec-1")
  }

  @Test("downloadRecording returns the raw bytes")
  func downloadReturnsBytes() async throws {
    let payload = Data("synthetic-media".utf8)
    let transport = ReplayTransport { _, _, _, _ in
      var headers = HTTPFields()
      headers[.contentType] = "application/octet-stream"
      return (HTTPResponse(status: .init(code: 200), headerFields: headers), HTTPBody(payload))
    }
    let client = try client(transport)
    let data = try await client.downloadRecording(key: "rec-1", quality: "source")
    #expect(data == payload)
  }
}
