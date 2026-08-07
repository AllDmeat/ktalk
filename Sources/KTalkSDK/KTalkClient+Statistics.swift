import Foundation

extension KTalkClient {
  /// Aggregate domain statistics.
  public typealias DomainStatistics =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Domains_TalkDomainStatistics
  /// Online conference statistics.
  public typealias ConferencesOnline =
    Components.Schemas.SkbKontur_Talk_Web_Entities_TalkConferencesOnlineStatistics
  /// Deepfake-detection statistics.
  public typealias DeepFakeStatistics =
    Components.Schemas
    .SkbKontur_Talk_DeepFakeDetector_Api_Models_TalkDeepFakeDetectionDomainStatistics
  /// Kiosk statistics.
  public typealias KioskStatistics = Components.Schemas
    .SkbKontur_Talk_Kiosk_Statistics_KiosksStatistics
  /// Online kiosk statistics.
  public typealias KiosksOnline =
    Components.Schemas.SkbKontur_Talk_Web_Entities_TalkKiosksOnlineStatistics
  /// Online recording statistics.
  public typealias RecordingsOnline =
    Components.Schemas.SkbKontur_Talk_Web_Entities_TalkRecordingsOnlineStatistics
  /// Recording statistics.
  public typealias RecordingsStatistics =
    Components.Schemas.SkbKontur_Talk_Web_Entities_TalkRecordingsStatistics
  /// Live online counters.
  public typealias OnlineCounters = Components.Schemas
    .SkbKontur_Talk_Web_Entities_TalkOnlineCounters
  /// Online stream statistics.
  public typealias StreamsOnline =
    Components.Schemas.SkbKontur_Talk_Web_Entities_TalkStreamsOnlineStatistics
  /// Total recording-size statistics.
  public typealias TotalRecordingsSize =
    Components.Schemas.SkbKontur_Talk_Web_Entities_TalkTotalRecordingSizeStatistics
  /// Whiteboard statistics.
  public typealias WhiteboardsStatistics =
    Components.Schemas.SkbKontur_Talk_Whiteboards_Api_Models_TalkWhiteboardsStatistics

  /// Statistics on active users for a window.
  public func domainStatistics(start: Date? = nil, end: Date? = nil) async throws(KTalkError)
    -> DomainStatistics
  {
    try await call {
      switch try await client.domainGetStatistics(.init(query: .init(start: start, end: end))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Statistics on all registered users.
  public func registeredUsersStatistics() async throws(KTalkError) -> DomainStatistics {
    try await call {
      switch try await client.domainGetStatisticsAll(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Conference statistics for a window.
  public func conferenceStatistics(fromDate: Date? = nil, toDate: Date? = nil)
    async throws(KTalkError) -> DomainStatistics
  {
    try await call {
      switch try await client.domainStatsGetConferenceStatistics(
        .init(query: .init(fromDate: fromDate, toDate: toDate)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Recording statistics for a window.
  public func recordingsStatistics(start: Date? = nil, end: Date? = nil) async throws(KTalkError)
    -> RecordingsStatistics
  {
    try await call {
      switch try await client.domainStatsGetRecordingsStatistics(
        .init(query: .init(start: start, end: end)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Kiosk statistics for a window.
  public func kioskStatistics(start: Date? = nil, end: Date? = nil) async throws(KTalkError)
    -> KioskStatistics
  {
    try await call {
      switch try await client.domainStatsGetKioskStatistics(
        .init(query: .init(start: start, end: end)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Live online counters for the domain.
  public func onlineCounters() async throws(KTalkError) -> OnlineCounters {
    try await call {
      switch try await client.domainStatsGetStatsOnline(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Online conference statistics.
  public func conferencesOnline() async throws(KTalkError) -> ConferencesOnline {
    try await call {
      switch try await client.domainStatsGetConferencesOnlineStats(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Online recording statistics.
  public func recordingsOnline() async throws(KTalkError) -> RecordingsOnline {
    try await call {
      switch try await client.domainStatsGetRecordingsOnlineStats(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Online kiosk statistics.
  public func kiosksOnline() async throws(KTalkError) -> KiosksOnline {
    try await call {
      switch try await client.domainStatsGetKiosksOnlineStats(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Online stream statistics.
  public func streamsOnline() async throws(KTalkError) -> StreamsOnline {
    try await call {
      switch try await client.domainStatsGetStreamsOnlineStats(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Total recording-size statistics.
  public func totalRecordingsSize() async throws(KTalkError) -> TotalRecordingsSize {
    try await call {
      switch try await client.domainStatsGetTotalRecordingsSize(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Whiteboard statistics.
  public func whiteboardsStatistics() async throws(KTalkError) -> WhiteboardsStatistics {
    try await call {
      switch try await client.domainStatsGetWhiteboardsStatistics(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Deepfake-detection statistics.
  public func deepFakeStatistics() async throws(KTalkError) -> DeepFakeStatistics {
    try await call {
      switch try await client.domainStatsGetDeepFakeDetectionStatistics(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// The tariff expiration date, if any.
  public func tariffExpirationDate() async throws(KTalkError) -> Date? {
    try await call {
      switch try await client.domainStatsGetTariffExpirationDate(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }
}
