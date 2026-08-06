import Foundation
import OpenAPIRuntime
import Testing

@testable import KTalkSDK

@Suite("Rooms")
struct RoomsTests {
  private func client(_ transport: any ClientTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  @Test("room(name:) decodes a room")
  func getDecodesRoom() async throws {
    let client = try client(try ReplayTransport.fixture(named: "room"))
    let room = try await client.room(name: "demo")
    #expect(room.roomName == "demo")
    #expect(room.conferenceId == "conf-1")
  }

  @Test("room(name:) maps 404 to notFound")
  func getMapsNotFound() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 404))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.room(name: "missing")
    }
    guard case .notFound(let resource, _) = error else {
      Issue.record("expected .notFound, got \(String(describing: error))")
      return
    }
    #expect(resource == "room")
  }

  @Test("addModerator returns the updated room")
  func addModeratorReturnsRoom() async throws {
    let client = try client(try ReplayTransport.fixture(named: "room"))
    let room = try await client.addModerator(roomName: "demo", userRef: "user-1")
    #expect(room.roomName == "demo")
  }

  @Test("endConference succeeds on an empty 200")
  func endConferenceSucceeds() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 200))
    try await client.endConference(roomName: "demo")
  }

  @Test("setRoomLock sends the request and succeeds on 200")
  func setRoomLockSucceeds() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 200))
    let data = try ReplayTransport.fixtureData(named: "lock-request")
    let request = try JSONDecoder().decode(KTalkClient.LockRoomRequest.self, from: data)
    try await client.setRoomLock(roomName: "demo", request: request)
  }

  @Test("write operations surface 403 as forbidden")
  func writeMapsForbidden() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 403))
    let error = await #expect(throws: KTalkError.self) {
      try await client.endConference(roomName: "demo")
    }
    guard case .forbidden = error else {
      Issue.record("expected .forbidden, got \(String(describing: error))")
      return
    }
  }
}
