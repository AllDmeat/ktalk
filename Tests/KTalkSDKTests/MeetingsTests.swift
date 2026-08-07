import Foundation
import OpenAPIRuntime
import Testing

@testable import KTalkSDK

@Suite("Meetings")
struct MeetingsTests {
  private func client(_ transport: any ClientTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  private let start = Date(timeIntervalSince1970: 1_767_312_000)

  @Test("listMeetings decodes the result items")
  func listDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "meetings-list"))
    let result = try await client.listMeetings(email: "user@example.com", start: start)
    #expect(result.items?.count == 1)
    #expect(result.items?.first?.id == "evt-1")
  }

  @Test("listMeetings maps 403 to forbidden")
  func listForbidden() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 403))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.listMeetings(email: "user@example.com", start: start)
    }
    guard case .forbidden = error else {
      Issue.record("expected .forbidden, got \(String(describing: error))")
      return
    }
  }

  @Test("createMeeting sends the body and decodes the meeting")
  func createDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "meeting"))
    let event = try JSONDecoder.iso8601.decode(
      KTalkClient.CreateMeeting.self,
      from: try ReplayTransport.fixtureData(named: "create-meeting"))
    let meeting = try await client.createMeeting(email: "user@example.com", event: event)
    #expect(meeting.id == "evt-1")
  }

  @Test("cancelMeeting succeeds on 200 and maps 404")
  func cancel() async throws {
    let ok = try client(ReplayTransport.returning(statusCode: 200))
    try await ok.cancelMeeting(email: "user@example.com", eventId: "evt-1")

    let missing = try client(ReplayTransport.returning(statusCode: 404))
    let error = await #expect(throws: KTalkError.self) {
      try await missing.cancelMeeting(email: "user@example.com", eventId: "gone")
    }
    guard case .notFound(let resource, _) = error else {
      Issue.record("expected .notFound, got \(String(describing: error))")
      return
    }
    #expect(resource == "meeting")
  }

  @Test("recurrenceSeries decodes")
  func recurrenceDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "meeting"))
    let meeting = try await client.recurrenceSeries(email: "user@example.com", eventId: "evt-1")
    #expect(meeting.id == "evt-1")
  }
}

extension JSONDecoder {
  /// A decoder configured for the API's ISO 8601 dates, shared by tests that build request bodies.
  static var iso8601: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}
