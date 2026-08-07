import Foundation

extension KTalkClient {
  /// The domain audit log.
  public typealias AuditLog = Components.Schemas.SkbKontur_Talk_Web_Entities_TalkAuditLogResponse
  /// A list of past conferences in the space.
  public typealias ConferenceHistory =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Conferences_TalkConferenceInfos
  /// Metadata about a past conference.
  public typealias Conference =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Conferences_TalkConference
  /// Enriched artifacts of a past conference.
  public typealias EnrichedConference =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Conferences_TalkEnrichedConference
  /// A conference's participants report.
  public typealias ParticipantsReport =
    Components.Schemas
    .SkbKontur_Talk_Web_Entities_Conferences_Report_TalkConferenceParticipantsReport
  /// A conference's activity report.
  public typealias ActivityReport =
    Components.Schemas
    .SkbKontur_Talk_Web_Entities_Conferences_Report_TalkConferenceActivityReport
  /// A conference's chat report.
  public typealias ChatReport =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Conferences_Report_TalkConferenceChatReport
  /// A room statistics report.
  public typealias RoomReport =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Statistics_RoomStatisticsReport

  /// Fetches the domain audit log for a time window.
  public func auditLog(startTime: Date, endTime: Date) async throws(KTalkError) -> AuditLog {
    try await call {
      let output = try await client.auditLogGetAuditLogEvents(
        .init(query: .init(startTime: startTime, endTime: endTime)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      }
    }
  }

  /// Lists past conferences in the space.
  public func conferences(
    fromDate: Date? = nil, toDate: Date? = nil, skip: Int? = nil, take: Int? = nil,
    roomNames: [String]? = nil
  ) async throws(KTalkError) -> ConferenceHistory {
    try await call {
      let output = try await client.domainConferencesHistoryGetDomainConferences(
        .init(
          query: .init(
            fromDate: fromDate, toDate: toDate, skip: skip.map(Int32.init),
            take: take.map(Int32.init), roomName: roomNames)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      default: throw KTalkError.unexpectedResponse(statusCode: 400, body: nil)
      }
    }
  }

  /// Fetches metadata about a past conference.
  public func conference(key: String) async throws(KTalkError) -> Conference {
    try await call {
      let output = try await client.conferencesHistoryGetConferenceHistory(
        .init(path: .init(conferenceKey: key)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .notFound: throw KTalkError.notFound(resource: "conference", identifier: key)
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "conference", identifier: key)
      }
    }
  }

  /// Fetches enriched artifacts of a past conference.
  public func enrichedConference(key: String) async throws(KTalkError) -> EnrichedConference {
    try await call {
      let output = try await client.conferencesHistoryGetEnrichedConferenceHistory(
        .init(path: .init(conferenceKey: key)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .notFound: throw KTalkError.notFound(resource: "conference", identifier: key)
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "conference", identifier: key)
      }
    }
  }

  /// Fetches a conference's participants report.
  public func conferenceParticipants(key: String) async throws(KTalkError) -> ParticipantsReport {
    try await call {
      let output = try await client.conferenceReportsGetConferenceParticipantsReport(
        .init(path: .init(conferenceKey: key)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .notFound: throw KTalkError.notFound(resource: "conference", identifier: key)
      case .forbidden: throw KTalkError.forbidden
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "conference", identifier: key)
      }
    }
  }

  /// Fetches a conference's activity report.
  public func conferenceActivity(key: String, skip: Int? = nil, take: Int? = nil)
    async throws(KTalkError) -> ActivityReport
  {
    try await call {
      let output = try await client.conferenceReportsGetConferenceActivityReport(
        .init(
          path: .init(conferenceKey: key),
          query: .init(skip: skip.map(Int32.init), take: take.map(Int32.init))))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .notFound: throw KTalkError.notFound(resource: "conference", identifier: key)
      case .forbidden: throw KTalkError.forbidden
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "conference", identifier: key)
      }
    }
  }

  /// Fetches a conference's chat report.
  public func conferenceChat(key: String, skip: Int? = nil, take: Int? = nil)
    async throws(KTalkError) -> ChatReport
  {
    try await call {
      let output = try await client.conferenceReportsGetConferenceChatReport(
        .init(
          path: .init(conferenceKey: key),
          query: .init(skip: skip.map(Int32.init), take: take.map(Int32.init))))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .notFound: throw KTalkError.notFound(resource: "conference", identifier: key)
      case .forbidden: throw KTalkError.forbidden
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "conference", identifier: key)
      default: throw KTalkError.unexpectedResponse(statusCode: 400, body: nil)
      }
    }
  }

  /// Fetches a room statistics report from `from` onward.
  public func roomReport(roomName: String, from: Date, to: Date? = nil)
    async throws(KTalkError) -> RoomReport
  {
    try await call {
      let output = try await client.roomReportGetRoomStatisticsReport(
        .init(path: .init(roomName: roomName), query: .init(from: from, to: to)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "room", identifier: roomName)
      }
    }
  }
}
