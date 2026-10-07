import Foundation
import OpenAPIRuntime

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
        .init(
          query: .init(
            skip: skip.map { Int32(clamping: $0) }, take: take.map { Int32(clamping: $0) })))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      case .badRequest: throw KTalkError.unexpectedResponse(statusCode: 400, body: nil)
      case .forbidden: throw KTalkError.forbidden
      case .notFound: throw KTalkError.unexpectedResponse(statusCode: 404, body: nil)
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
      case .badRequest: throw KTalkError.unexpectedResponse(statusCode: 400, body: nil)
      case .forbidden: throw KTalkError.forbidden
      case .notFound: throw KTalkError.notFound(resource: "calendar server", identifier: id)
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
      case .badRequest: throw KTalkError.unexpectedResponse(statusCode: 400, body: nil)
      case .forbidden: throw KTalkError.forbidden
      case .notFound: throw KTalkError.unexpectedResponse(statusCode: 404, body: nil)
      case .requestTimeout: throw KTalkError.unexpectedResponse(statusCode: 408, body: nil)
      case .conflict: throw KTalkError.unexpectedResponse(statusCode: 409, body: nil)
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
      case .badRequest: throw KTalkError.unexpectedResponse(statusCode: 400, body: nil)
      case .forbidden: throw KTalkError.forbidden
      case .notFound: throw KTalkError.notFound(resource: "calendar server", identifier: id)
      case .requestTimeout: throw KTalkError.unexpectedResponse(statusCode: 408, body: nil)
      case .conflict: throw KTalkError.unexpectedResponse(statusCode: 409, body: nil)
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
      case .badRequest: throw KTalkError.unexpectedResponse(statusCode: 400, body: nil)
      case .forbidden: throw KTalkError.forbidden
      case .notFound: throw KTalkError.notFound(resource: "calendar server", identifier: id)
      case .requestTimeout: throw KTalkError.unexpectedResponse(statusCode: 408, body: nil)
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

  // MARK: - Deepfake source files

  /// Downloads the reference file of one deepfake-detection task.
  public func deepFakeTaskFile(conferenceKey: String, taskKey: String) async throws(KTalkError)
    -> Data
  {
    try await call {
      switch try await client.deepFakeDetectorGetTaskSourceFile(
        .init(path: .init(conferenceKey: conferenceKey, taskKey: taskKey)))
      {
      case .ok(let ok): return try await Data(collecting: ok.body.any, upTo: .max)
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "task", identifier: taskKey)
      }
    }
  }

  /// Downloads an archive of every deepfake-detection reference file of a conference.
  public func deepFakeTaskFiles(conferenceKey: String) async throws(KTalkError) -> Data {
    try await call {
      switch try await client.deepFakeDetectorGetTaskSourceFiles(
        .init(path: .init(conferenceKey: conferenceKey)))
      {
      case .ok(let ok): return try await Data(collecting: ok.body.any, upTo: .max)
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "conference", identifier: conferenceKey)
      }
    }
  }
}
