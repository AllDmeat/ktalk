import Foundation
import OpenAPIRuntime

extension KTalkClient {
  /// A conference recording stored in the space.
  public typealias Recording =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Recordings_TalkDomainConferenceRecording
  /// A recording's speaker-by-speaker transcript.
  public typealias RecordingTranscript =
    Components.Schemas.SkbKontur_Talk_SpeechCore_Api_Models_Transcription_TalkTranscript
  /// A recording's summary / protocol.
  public typealias RecordingSummary =
    Components.Schemas.SkbKontur_Talk_SpeechCore_Api_Models_Summarization_TalkSummaryResult

  /// Lists recordings in the space (one page).
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
        .init(query: .init(pageTokenString: pageToken, query: query, top: limit.map(Int32.init)))
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

  /// Fetches a single recording by key.
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

  /// Fetches a recording's transcript.
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

  /// Fetches a recording's summary / protocol.
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
  public func downloadRecording(key: String, quality: String) async throws(KTalkError) -> Data {
    try await call {
      let output = try await client.recordingsDownloadFile(
        .init(path: .init(qualityName: quality, recordingKey: key)))
      switch output {
      case .ok(let ok):
        return try await Data(collecting: ok.body.binary, upTo: .max)
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "recording file", identifier: key)
      }
    }
  }
}
