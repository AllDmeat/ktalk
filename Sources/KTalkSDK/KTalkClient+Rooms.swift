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
  /// A page of a room's recordings, with their participants.
  public typealias RoomRecordingsPage =
    Components.Schemas
    .SkbKontur_Talk_Web_Entities_TalkPageSkbKontur_Talk_Web_Entities_Rooms_TalkClippedRoomRecordingWithParticipants
  /// The result of uploading a file to a room.
  public typealias RoomUploadResult = Components.Schemas
    .SkbKontur_Talk_Api_Entities_Files_TalkUploadResult
  /// A change to a room's simultaneous translation.
  public typealias SimultaneousTranslationRequest =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_TalkSimultaneousTranslationUpdateRequest
  /// A room's SIP number and URI.
  public typealias RoomSipSettings = Components.Schemas
    .SkbKontur_Talk_Web_Entities_Rooms_RoomSipSettings
  /// Parameters for starting a room's conference.
  public typealias StartConferenceProperties =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_TalkStartConferenceProperties
  /// The result of starting a room's conference.
  public typealias StartConferenceResult =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_TalkStartConferenceResult
  /// A request to remove a participant from a room's conference.
  public typealias KickUserRequest = Components.Schemas
    .SkbKontur_Talk_Web_Entities_Rooms_KickUserRequest
  /// A request to rename an anonymous participant.
  public typealias ChangeUserNameRequest =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_ChangeUserNameRequest
  /// The participants currently in a room.
  public typealias RoomOnlineUsers =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_TalkRoomOnlineUsersList
  /// How long a room's conference may still run.
  public typealias RoomDurationLimits =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_TalkRoomDurationLimits
  /// Parameters for creating a chat room.
  public typealias CreateMessengerRoomRequest =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_CreateMessengerRoomRequest
  /// The created chat room.
  public typealias CreateMessengerRoomResponse =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Rooms_CreateMessengerRoomResponse

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

  /// Lists a room's recordings, one page at a time.
  public func roomRecordings(name: String, top: Int? = nil, pageToken: String? = nil)
    async throws(KTalkError) -> RoomRecordingsPage
  {
    try await call {
      switch try await client.roomsGetRoomRecordings(
        .init(
          path: .init(roomName: name),
          query: .init(top: top.map { Int32(clamping: $0) }, pageTokenString: pageToken)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Uploads a file to a room's chat or conference, up to 50 MB.
  public func uploadRoomFile(roomName name: String, file: UploadFile) async throws(KTalkError)
    -> RoomUploadResult
  {
    try await call {
      let parts: [Operations.RoomsUploadFile.Input.Body.MultipartFormPayload] = [
        .undocumented(file.multipartPart(name: "file"))
      ]
      switch try await client.roomsUploadFile(
        .init(path: .init(roomName: name), body: .multipartForm(.init(parts))))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Turns a room's simultaneous translation on or off and sets its language pairs.
  public func setSimultaneousTranslation(
    roomName name: String, request: SimultaneousTranslationRequest
  ) async throws(KTalkError) -> Room {
    try await call {
      switch try await client.roomsUpdateSimultaneousTranslation(
        .init(path: .init(roomName: name), body: .json(request)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Gives a room a SIP number.
  public func generateSipNumber(roomName name: String) async throws(KTalkError) -> RoomSipSettings {
    try await call {
      switch try await client.roomsGenerateSipNumber(.init(path: .init(roomName: name))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Takes a room's SIP number away.
  public func disableSipNumber(roomName name: String) async throws(KTalkError) {
    try await call {
      switch try await client.roomsDisableSipNumber(.init(path: .init(roomName: name))) {
      case .ok: return
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Allows a user to write in a room's chat channel.
  public func addChatChannelUser(roomName name: String, userRef: String) async throws(KTalkError)
    -> Room
  {
    try await call {
      switch try await client.roomsAppendChatChannelAllowedUser(
        .init(path: .init(roomName: name, userRef: userRef)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Takes a user's right to write in a room's chat channel away.
  public func removeChatChannelUser(roomName name: String, userRef: String)
    async throws(KTalkError) -> Room
  {
    try await call {
      switch try await client.roomsRemovedChatChannelAllowedUser(
        .init(path: .init(roomName: name, userRef: userRef)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Starts a room's conference.
  public func startConference(roomName name: String, properties: StartConferenceProperties)
    async throws(KTalkError) -> StartConferenceResult
  {
    try await call {
      switch try await client.roomsStartRoomConference(
        .init(path: .init(roomName: name), body: .json(properties)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Removes a participant from a room's conference.
  public func kickUser(roomName name: String, request: KickUserRequest) async throws(KTalkError) {
    try await call {
      switch try await client.roomsKickUser(
        .init(path: .init(roomName: name), body: .json(request)))
      {
      case .ok: return
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Renames an anonymous participant in a room's conference.
  public func changeParticipantName(roomName name: String, request: ChangeUserNameRequest)
    async throws(KTalkError)
  {
    try await call {
      switch try await client.roomsChangeUserName(
        .init(path: .init(roomName: name), body: .json(request)))
      {
      case .ok: return
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Lists the participants currently in a room.
  public func onlineUsers(roomName name: String) async throws(KTalkError) -> RoomOnlineUsers {
    try await call {
      switch try await client.roomsGetOnlineUsers(.init(path: .init(roomName: name))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Reports how long a room's conference may still run.
  public func conferenceLimits(roomName name: String, forceStart: Bool? = nil)
    async throws(KTalkError) -> RoomDurationLimits
  {
    try await call {
      switch try await client.roomsGetCurrentConferenceLimits(
        .init(path: .init(roomName: name), query: .init(forceStart: forceStart)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "room", identifier: name)
      }
    }
  }

  /// Creates a chat room.
  public func createMessengerRoom(_ request: CreateMessengerRoomRequest) async throws(KTalkError)
    -> CreateMessengerRoomResponse
  {
    try await call {
      switch try await client.messengerCreateMessengerRoom(.init(body: .json(request))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }
}
