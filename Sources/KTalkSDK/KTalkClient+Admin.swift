import Foundation

extension KTalkClient {
  /// A calendar server.
  public typealias CalendarServer =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_CalendarServerResponseModel
  /// A calendar server summary.
  public typealias CalendarServerSummary =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_CalendarServerShortResponseModel
  /// A request to add a calendar server.
  public typealias CalendarServerCreate =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_CalendarServerCreateModel
  /// A request to update a calendar server.
  public typealias CalendarServerUpdate =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_CalendarServerUpdateModel
  /// A deepfake-detection report for a conference.
  public typealias DeepFakeReport =
    Components.Schemas.SkbKontur_Talk_DeepFakeDetector_Api_Models_TalkConferenceDeepFakeReport
  /// Deepfake-detection statistics for a period.
  public typealias DeepFakeDetectionStatistic =
    Components.Schemas.SkbKontur_Talk_DeepFakeDetector_Api_Models_TalkDeepFakeDetectionStatistic
  /// The domain's registered applications (API keys).
  public typealias ApplicationsList =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Domains_TalkDomainApplicationsList
  /// Access information for an API key.
  public typealias ApplicationAccessInfo =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Domains_TalkDomainApplicationAccessInfo

  // MARK: - Calendar servers

  /// Lists the additional calendar servers.
  public func calendarServers(skip: Int? = nil, take: Int? = nil) async throws(KTalkError)
    -> [CalendarServerSummary]
  {
    try await call {
      switch try await client.calendarGetCalendarServers(
        .init(query: .init(skip: skip.map(Int32.init), take: take.map(Int32.init))))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      default: throw KTalkError.unexpectedResponse(statusCode: 400, body: nil)
      }
    }
  }

  /// Fetches a calendar server by id.
  public func calendarServer(id: String) async throws(KTalkError) -> CalendarServer {
    try await call {
      switch try await client.calendarGetCalendarServer(
        .init(path: .init(calendarServerId: id)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "calendar server", identifier: id)
      default: throw KTalkError.unexpectedResponse(statusCode: 400, body: nil)
      }
    }
  }

  /// Adds a calendar server.
  public func addCalendarServer(_ model: CalendarServerCreate) async throws(KTalkError)
    -> CalendarServer
  {
    try await call {
      switch try await client.calendarAddCalendarServer(.init(body: .json(model))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      default: throw KTalkError.unexpectedResponse(statusCode: 400, body: nil)
      }
    }
  }

  /// Updates a calendar server.
  public func updateCalendarServer(id: String, model: CalendarServerUpdate) async throws(KTalkError)
  {
    try await call {
      switch try await client.calendarUpdateCalendarServer(
        .init(path: .init(calendarServerId: id), body: .json(model)))
      {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "calendar server", identifier: id)
      default: throw KTalkError.unexpectedResponse(statusCode: 400, body: nil)
      }
    }
  }

  /// Deletes a calendar server.
  public func deleteCalendarServer(id: String) async throws(KTalkError) {
    try await call {
      switch try await client.calendarDeleteCalendarServer(
        .init(path: .init(calendarServerId: id)))
      {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "calendar server", identifier: id)
      default: throw KTalkError.unexpectedResponse(statusCode: 400, body: nil)
      }
    }
  }

  // MARK: - Deepfake detection

  /// Fetches the deepfake-detection report for a conference.
  public func deepFakeReport(conferenceKey: String, timezone: String? = nil)
    async throws(KTalkError) -> DeepFakeReport
  {
    try await call {
      switch try await client.deepFakeDetectorGetConferenceReport(
        .init(path: .init(conferenceKey: conferenceKey), query: .init(timezone: timezone)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "conference", identifier: conferenceKey)
      }
    }
  }

  /// Fetches deepfake-detection statistics for a period.
  public func deepFakeDetectionStatistic() async throws(KTalkError) -> DeepFakeDetectionStatistic {
    try await call {
      switch try await client.deepFakeDetectorGetStatistic(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  // MARK: - API keys

  /// Lists the domain's registered applications (API keys).
  public func applications() async throws(KTalkError) -> ApplicationsList {
    try await call {
      switch try await client.domainApplicationGetApplications(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Fetches the access information for the current API key.
  public func applicationAccessInfo() async throws(KTalkError) -> ApplicationAccessInfo {
    try await call {
      switch try await client.domainApplicationGetApplicationAccessInfo(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }
}
