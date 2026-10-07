import Foundation

extension KTalkClient {
  /// A room in the space.
  public typealias Room = Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_TalkRoom
  /// Parameters for creating or updating a room.
  public typealias RoomParams = Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_TalkRoomParams
  /// A change to whether external participants can join a room.
  public typealias AnonymousAccessRequest =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_UpdateAnonymousAccessRequest
  /// Parameters for notifying users of a call from a room.
  public typealias NotifyCallParams =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calls_TalkNotifyCallParameters
  /// The result of a call notification.
  public typealias NotifyCallResult =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calls_TalkNotifyCallResult
  /// Parameters for cancelling a call.
  public typealias CancelCallParams =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calls_TalkCancelCallParameters
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

  /// Changes whether external participants can join a room.
  public func setAnonymousAccess(roomName name: String, request: AnonymousAccessRequest)
    async throws(KTalkError) -> Room
  {
    try await call {
      switch try await client.roomsUpdateAnonymousAccess(
        .init(path: .init(roomName: name), body: .json(request)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Notifies users of a call from a room.
  public func notifyCall(roomName name: String, params: NotifyCallParams) async throws(KTalkError)
    -> NotifyCallResult
  {
    try await call {
      switch try await client.roomCallsNotifyCall(
        .init(path: .init(roomName: name), body: .json(params)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Cancels a call from a room.
  public func cancelCall(roomName name: String, params: CancelCallParams) async throws(KTalkError) {
    try await call {
      switch try await client.roomCallsCancelCall(
        .init(path: .init(roomName: name), body: .json(params)))
      {
      case .ok: return
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }
}
