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
      headers[.contentType] = "video/mp4"
      return (HTTPResponse(status: .init(code: 200), headerFields: headers), HTTPBody(payload))
    }
    let client = try client(transport)
    let data = try await client.downloadRecording(key: "rec-1", quality: "source")
    #expect(data == payload)
  }

  @Test("listAccessibleRecordings decodes the recordings array and sends top/skip")
  func listAccessibleDecodes() async throws {
    let transport = try ReplayTransport.fixture(named: "accessible-recordings-list")
    let client = try client(transport)
    let recordings = try await client.listAccessibleRecordings(top: 2, skip: 4)
    #expect(recordings.map(\.id) == ["rec-2", "rec-1"])
    #expect(recordings.first?.title == "Synthetic retro")
    let path = transport.lastRequest?.request.path ?? ""
    #expect(path.hasPrefix("/api/recordings?"))
    #expect(path.contains("top=2"))
    #expect(path.contains("skip=4"))
  }

  /// A transport that serves `total` recordings by `skip`/`top`, optionally capping the page
  /// size, ignoring `skip` or omitting ids, and records each request.
  private func pagingTransport(
    total: Int, cap: Int = .max, ignoreSkip: Bool = false, withIDs: Bool = true
  ) -> ReplayTransport {
    ReplayTransport { request, _, _, _ in
      let query = URLComponents(string: request.path ?? "")?.queryItems ?? []
      let skip = ignoreSkip ? 0 : Int(query.first { $0.name == "skip" }?.value ?? "0") ?? 0
      let top = min(Int(query.first { $0.name == "top" }?.value ?? "10") ?? 10, cap)
      let ids = (skip..<min(skip + top, total)).map {
        withIDs ? #"{"id":"rec-\#($0)"}"# : #"{"title":"rec-\#($0)"}"#
      }
      var headers = HTTPFields()
      headers[.contentType] = "application/json"
      return (
        HTTPResponse(status: .init(code: 200), headerFields: headers),
        HTTPBody(#"{"recordings":[\#(ids.joined(separator: ","))]}"#)
      )
    }
  }

  @Test("allAccessibleRecordings stops when the server ignores skip and sends no ids")
  func allAccessibleIgnoredSkipWithoutIDs() async throws {
    let transport = pagingTransport(total: 500, ignoreSkip: true, withIDs: false)
    let recordings = try await client(transport).allAccessibleRecordings()
    #expect(recordings.count == KTalkClient.accessibleRecordingsMaxPageSize)
    #expect(recordings.first?.title == "rec-0")
    #expect(transport.recordedRequests.count == 2)
  }

  @Test("allAccessibleRecordings reads every page of recordings without ids")
  func allAccessibleWithoutIDs() async throws {
    let recordings = try await client(pagingTransport(total: 250, withIDs: false))
      .allAccessibleRecordings()
    #expect(recordings.count == 250)
    #expect(recordings.last?.title == "rec-249")
  }

  @Test("listAccessibleRecordings fails on a reply without the recordings list")
  func listAccessibleRejectsChangedShape() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 200, body: #"{"items":[]}"#))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.listAccessibleRecordings()
    }
    guard case .decodingError = error else {
      Issue.record("expected .decodingError, got \(String(describing: error))")
      return
    }
  }

  @Test("allAccessibleRecordings pages by skip until an empty page")
  func allAccessiblePages() async throws {
    let total = KTalkClient.accessibleRecordingsMaxPageSize + 3
    let transport = pagingTransport(total: total)
    let recordings = try await client(transport).allAccessibleRecordings()
    #expect(recordings.count == total)
    #expect(recordings.last?.id == "rec-\(total - 1)")
    #expect(transport.recordedRequests.count == 3)
  }

  @Test("allAccessibleRecordings keeps going when the server caps the page size")
  func allAccessibleCappedPages() async throws {
    let recordings = try await client(pagingTransport(total: 120, cap: 50))
      .allAccessibleRecordings()
    #expect(recordings.count == 120)
  }

  @Test("allAccessibleRecordings stops when the server ignores skip")
  func allAccessibleIgnoredSkip() async throws {
    let transport = pagingTransport(total: 500, ignoreSkip: true)
    let recordings = try await client(transport).allAccessibleRecordings()
    #expect(recordings.count == KTalkClient.accessibleRecordingsMaxPageSize)
    #expect(transport.recordedRequests.count == 2)
  }

  @Test("accessibleRecording(key:) decodes from /api/Recordings/{key}")
  func getAccessibleDecodes() async throws {
    let transport = try ReplayTransport.fixture(named: "accessible-recording")
    let recording = try await client(transport).accessibleRecording(key: "rec-1")
    #expect(recording.id == "rec-1")
    #expect(recording.title == "Synthetic standup")
    #expect(transport.lastRequest?.request.path == "/api/Recordings/rec-1")
  }

  @Test("activeRecording maps 404 to a missing active recording, not a missing room")
  func activeRecordingNotFound() async throws {
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client(ReplayTransport.returning(statusCode: 404)).activeRecording(
        roomName: "demo")
    }
    guard case .notFound(let resource, let identifier) = error else {
      Issue.record("expected .notFound, got \(String(describing: error))")
      return
    }
    #expect(resource == "active recording in room")
    #expect(identifier == "demo")
  }

  @Test("accessibleRecording(key:) maps 404 to notFound")
  func getAccessibleMapsNotFound() async throws {
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client(ReplayTransport.returning(statusCode: 404)).accessibleRecording(
        key: "missing")
    }
    guard case .notFound(let resource, _) = error else {
      Issue.record("expected .notFound, got \(String(describing: error))")
      return
    }
    #expect(resource == "recording")
  }
}
