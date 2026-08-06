import Foundation

extension KTalkClient {
  /// A room in the space.
  public typealias Room = Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_TalkRoom
  /// Parameters for creating or updating a room.
  public typealias RoomParams = Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_TalkRoomParams
  /// A request to set or clear a room's PIN and masking settings.
  public typealias LockRoomRequest =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_LockRoomRequest

  /// Fetches a room by name.
  public func room(name: String) async throws(KTalkError) -> Room {
    try await call {
      let output = try await client.roomsGet(.init(path: .init(roomName: name)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "room", identifier: name)
      }
    }
  }

  /// Creates or updates a room.
  public func updateRoom(name: String, params: RoomParams) async throws(KTalkError) -> Room {
    try await call {
      let output = try await client.roomsUpdate(
        .init(path: .init(roomName: name), body: .json(params)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "room", identifier: name)
      }
    }
  }

  /// Forcibly ends the conference in a room for all participants.
  public func endConference(roomName name: String) async throws(KTalkError) {
    try await call {
      let output = try await client.roomsEndConference(.init(path: .init(roomName: name)))
      switch output {
      case .ok: return
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "room", identifier: name)
      }
    }
  }

  /// Sets or clears a room's PIN and masking settings.
  public func setRoomLock(roomName name: String, request: LockRoomRequest) async throws(KTalkError)
  {
    try await call {
      let output = try await client.roomsSetRoomPinCode(
        .init(path: .init(roomName: name), body: .json(request)))
      switch output {
      case .ok: return
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "room", identifier: name)
      }
    }
  }

  /// Adds a moderator to a room.
  public func addModerator(roomName name: String, userRef: String) async throws(KTalkError) -> Room
  {
    try await call {
      let output = try await client.roomsAppendModerator(
        .init(path: .init(roomName: name, userRef: userRef)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "room moderator", identifier: userRef)
      }
    }
  }

  /// Removes a moderator from a room.
  public func removeModerator(roomName name: String, userRef: String) async throws(KTalkError)
    -> Room
  {
    try await call {
      let output = try await client.roomsRemovedModerator(
        .init(path: .init(roomName: name, userRef: userRef)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "room moderator", identifier: userRef)
      }
    }
  }
}
