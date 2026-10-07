import Foundation
import OpenAPIRuntime

extension KTalkClient {
  /// A conference recording stored in the space.
  public typealias Recording =
    Components.Schemas.SkbKontur_Talk_Recordings_Api_TalkDomainConferenceRecording
  /// A recording's speaker-by-speaker transcript.
  public typealias RecordingTranscript =
    Components.Schemas.SkbKontur_Talk_SpeechCore_Api_Models_Transcription_TalkTranscript
  /// A recording's summary / protocol.
  public typealias RecordingSummary =
    Components.Schemas.SkbKontur_Talk_SpeechCore_Api_Models_Summarization_TalkSummaryResult

  /// A page of space recordings from the first-generation list endpoint.
  public typealias RecordingsListV1 =
    Components.Schemas.SkbKontur_Talk_Recordings_Api_TalkDomainRecordingsList
  /// The sort order of the first-generation recordings list.
  public typealias RecordingsOrderMode =
    Components.Schemas.SkbKontur_Talk_Recordings_Domain_RecordingsOrderMode
  /// A recording participant.
  public typealias RecordingParticipant =
    Components.Schemas.SkbKontur_Talk_Users_Api_Models_TalkUserBaseInfoRef
  /// The recording currently running in a room.
  public typealias ActiveRecording =
    Components.Schemas.SkbKontur_Talk_Recordings_Api_TalkActiveConferenceRecording
  /// Parameters for starting a recording.
  public typealias StartRecordingParams =
    Components.Schemas.SkbKontur_Talk_Recordings_Api_TalkStartRecordingParams
  /// A recording that has just been started.
  public typealias StartedRecording = Components.Schemas
    .SkbKontur_Talk_Recordings_Api_TalkRecordingInfo
  /// Parameters for editing a recording.
  public typealias RecordingUpdateParams =
    Components.Schemas.SkbKontur_Talk_Recordings_Api_TalkConferenceRecordingUpdateParams
  /// Who can open a recording.
  public typealias RecordingAccess =
    Components.Schemas.SkbKontur_Talk_Recordings_Api_RecordsResourceAccessResponse
  /// A change to who can open a recording.
  public typealias RecordingAccessPatch =
    Components.Schemas.SkbKontur_Talk_Recordings_Api_PatchRecordAccessRequest
  /// A summary kind: short summary or protocol.
  public typealias SummaryType =
    Components.Schemas.SkbKontur_Talk_SpeechCore_Api_Models_Summarization_TalkSummaryType
  /// A summary of one kind.
  public typealias TypedSummary =
    Components.Schemas.SkbKontur_Talk_SpeechCore_Api_Models_Summarization_TalkSummaryV2Result
  /// Transcript, short summary and protocol of a recording in one response.
  public typealias RecordingArtifacts =
    Components.Schemas.SkbKontur_Talk_SpeechCore_Api_Models_TalkCompositeSpeechCoreResult

  /// A recording as seen by a personal access token's user.
  public typealias AccessibleRecording =
    Components.Schemas.SkbKontur_Talk_Recordings_Api_TalkConferenceRecording

  /// The largest page `listAccessibleRecordings` accepts; the API rejects a bigger `top`.
  public static let accessibleRecordingsMaxPageSize = 100

  /// Lists recordings in the space (one page). Requires a space key.
  ///
  /// A space key (admin panel → API keys) sees every recording in the space. A personal
  /// access token gets `forbidden` here — use ``listAccessibleRecordings(top:skip:)``.
  ///
  /// - Parameters:
  ///   - pageToken: A cursor from a previous page's `nextPageToken` (`nil` for the first page).
  ///   - limit: Maximum number of recordings to return.
  ///   - query: Optional full-text query.
  public func listRecordings(
    pageToken: String? = nil,
    limit: Int? = nil,
    query: String? = nil
  ) async throws(KTalkError) -> Page<Recording> {
    try await call {
      let output = try await client.domainRecordingsGetV2(
        .init(
          query: .init(
            pageTokenString: pageToken, query: query, top: limit.map { Int32(clamping: $0) }))
      )
      switch output {
      case .ok(let ok):
        let payload = try ok.body.json
        return Page(
          items: payload.entities ?? [],
          nextPageToken: payload.nextPageToken,
          prevPageToken: payload.prevPageToken
        )
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      }
    }
  }

  /// Fetches a single recording by key. Requires a space key; with a personal access token
  /// use ``accessibleRecording(key:)``.
  public func recording(key: String) async throws(KTalkError) -> Recording {
    try await call {
      let output = try await client.domainRecordingsGetByKey(.init(path: .init(recordingKey: key)))
      switch output {
      case .ok(let ok):
        return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "recording", identifier: key)
      }
    }
  }

  /// Lists recordings available to a personal access token's user (one page), newest first.
  ///
  /// A personal access token (profile → Settings → API keys) acts with its user's rights,
  /// so this returns only the recordings that user can open — not the whole space. The
  /// endpoint is missing from the published spec; it was described by Kontur.Talk support.
  ///
  /// - Parameters:
  ///   - top: Page size, 1 to ``accessibleRecordingsMaxPageSize``; the server defaults to 10.
  ///   - skip: Number of recordings to skip.
  public func listAccessibleRecordings(
    top: Int? = nil,
    skip: Int? = nil
  ) async throws(KTalkError) -> [AccessibleRecording] {
    try await call {
      let output = try await client.recordingsGetAccessible(
        .init(
          query: .init(top: top.map { Int32(clamping: $0) }, skip: skip.map { Int32(clamping: $0) })
        ))
      switch output {
      case .ok(let ok):
        return try ok.body.json.recordings
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      }
    }
  }

  /// Fetches every recording available to a personal access token's user.
  ///
  /// The endpoint pages by offset and reports no total. Paging stops on an empty page rather
  /// than a short one, so a server that caps `top` below the requested size loses nothing,
  /// and it stops after a page that brings no recording with an unseen id, so a server that
  /// ignores `skip` cannot loop forever. Recordings without an id are kept in place. Recordings are de-duplicated by id, which absorbs one added
  /// mid-scan; one deleted mid-scan shifts the offset and the next recording can be missed —
  /// offset paging cannot tell.
  public func allAccessibleRecordings() async throws(KTalkError) -> [AccessibleRecording] {
    var all: [AccessibleRecording] = []
    var seen = Set<String>()
    var skip = 0
    while true {
      let page = try await listAccessibleRecordings(
        top: Self.accessibleRecordingsMaxPageSize, skip: skip)
      var unseen = 0
      for recording in page {
        guard let id = recording.id else {
          all.append(recording)  // no id to de-duplicate by; keep it in place
          continue
        }
        if seen.insert(id).inserted {
          all.append(recording)
          unseen += 1
        }
      }
      // A page without a single unseen id is the end, or a server repeating itself.
      if unseen == 0 { return all }
      skip += page.count
    }
  }

  /// Fetches a recording available to a personal access token's user. The endpoint is
  /// missing from the published spec; it was described by Kontur.Talk support.
  public func accessibleRecording(key: String) async throws(KTalkError) -> AccessibleRecording {
    try await call {
      let output = try await client.recordingsGetRecording(.init(path: .init(recordingKey: key)))
      switch output {
      case .ok(let ok):
        return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "recording", identifier: key)
      }
    }
  }

  /// Fetches a recording's transcript. Works with either key.
  public func recordingTranscript(key: String) async throws(KTalkError) -> RecordingTranscript {
    try await call {
      let output = try await client.recordingsTranscriptionGetRecordingTranscript(
        .init(path: .init(recordingKey: key)))
      switch output {
      case .ok(let ok):
        return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "transcript", identifier: key)
      }
    }
  }

  /// Fetches a recording's summary / protocol. Works with either key.
  public func recordingSummary(key: String) async throws(KTalkError) -> RecordingSummary {
    try await call {
      let output = try await client.recordingsTranscriptionGetRecordingTranscriptSummary(
        .init(path: .init(recordingKey: key)))
      switch output {
      case .ok(let ok):
        return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "summary", identifier: key)
      }
    }
  }

  /// Downloads a recording's media file for the given quality, returning the raw bytes.
  /// Buffers the whole file in memory — fine for reports, heavy for large archives or media.
  public func downloadRecording(key: String, quality: String) async throws(KTalkError) -> Data {
    try await call {
      let output = try await client.recordingsDownloadFile(
        .init(path: .init(qualityName: quality, recordingKey: key)))
      switch output {
      case .ok(let ok):
        return try await Data(collecting: ok.body.any, upTo: .max)
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "recording file", identifier: key)
      }
    }
  }

  /// Lists space recordings with the first-generation endpoint, paged by `skip`/`top`.
  public func listRecordingsV1(
    startFrom: Date? = nil, startTo: Date? = nil, skip: Int? = nil, top: Int? = nil,
    query: String? = nil, title: String? = nil, maxParticipantCount: Int? = nil,
    orderMode: RecordingsOrderMode? = nil
  ) async throws(KTalkError) -> RecordingsListV1 {
    try await call {
      switch try await client.domainRecordingsGet(
        .init(
          query: .init(
            startFrom: startFrom, startTo: startTo, skip: skip.map { Int32(clamping: $0) },
            query: query,
            title: title, maxParticipantCount: maxParticipantCount.map { Int32(clamping: $0) },
            top: top.map { Int32(clamping: $0) }, orderMode: orderMode)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Lists the participants of a recording.
  public func recordingParticipants(key: String, skip: Int? = nil, top: Int? = nil)
    async throws(KTalkError) -> [RecordingParticipant]
  {
    try await call {
      switch try await client.domainRecordingsFindParticipants(
        .init(
          path: .init(recordingKey: key),
          query: .init(skip: skip.map { Int32(clamping: $0) }, top: top.map { Int32(clamping: $0) })
        ))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "recording", identifier: key)
      }
    }
  }

  /// Protects a recording from deletion.
  public func setRecordingImmutable(key: String) async throws(KTalkError) {
    try await call {
      switch try await client.domainRecordingsSetImmutableRecording(
        .init(path: .init(recordingKey: key)))
      {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "recording", identifier: key)
      }
    }
  }

  /// Removes the deletion protection from a recording.
  public func unsetRecordingImmutable(key: String) async throws(KTalkError) {
    try await call {
      switch try await client.domainRecordingsUnsetImmutableRecording(
        .init(path: .init(recordingKey: key)))
      {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "recording", identifier: key)
      }
    }
  }

  /// Fetches the recording currently running in a room.
  public func activeRecording(roomName: String, sessionHall: String? = nil)
    async throws(KTalkError) -> ActiveRecording
  {
    try await call {
      switch try await client.recordingsGetActiveRecordingInfo(
        .init(query: .init(roomName: roomName, sessionHall: sessionHall)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "active recording in room", identifier: roomName)
      }
    }
  }

  /// Starts recording a conference.
  public func startRecording(_ params: StartRecordingParams) async throws(KTalkError)
    -> StartedRecording
  {
    try await call {
      switch try await client.recordingsStartRecording(.init(body: .json(params))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Edits a recording's title and description.
  public func editRecording(key: String, params: RecordingUpdateParams) async throws(KTalkError) {
    try await call {
      switch try await client.recordingsEditRecording(
        .init(path: .init(recordingKey: key), body: .json(params)))
      {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "recording", identifier: key)
      }
    }
  }

  /// Deletes a recording. `force` deletes it even when it is protected.
  public func deleteRecording(key: String, force: Bool? = nil) async throws(KTalkError) {
    try await call {
      switch try await client.recordingsDeleteRecording(
        .init(path: .init(recordingKey: key), query: .init(forceDelete: force)))
      {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "recording", identifier: key)
      }
    }
  }

  /// Fetches who can open a recording.
  public func recordingAccess(key: String) async throws(KTalkError) -> RecordingAccess {
    try await call {
      switch try await client.recordingsGetRecordingsAccess(.init(path: .init(recordingKey: key))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "recording", identifier: key)
      }
    }
  }

  /// Changes who can open a recording.
  public func updateRecordingAccess(key: String, patch: RecordingAccessPatch)
    async throws(KTalkError)
  {
    try await call {
      switch try await client.recordingsPatchRecordingsAccess(
        .init(path: .init(recordingKey: key), body: .json(patch)))
      {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "recording", identifier: key)
      }
    }
  }

  /// Fetches one kind of summary — short summary or protocol — of a recording.
  public func recordingSummaryByType(key: String, type: SummaryType) async throws(KTalkError)
    -> TypedSummary
  {
    try await call {
      switch try await client.recordingsTranscriptionGetRecordingTranscriptSummaryByType(
        .init(path: .init(recordingKey: key, summarizationType: type)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "summary", identifier: key)
      }
    }
  }

  /// Fetches a recording's transcript, short summary and protocol in one request.
  public func recordingArtifacts(key: String) async throws(KTalkError) -> RecordingArtifacts {
    try await call {
      switch try await client.recordingsTranscriptionGetRecordingTranscriptArtifacts(
        .init(path: .init(recordingKey: key)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "recording", identifier: key)
      }
    }
  }
}
