import Foundation

extension KTalkClient {
  /// A page of client telemetry from the first-generation endpoint.
  public typealias TelemetryV1 =
    Components.Schemas.SkbKontur_Talk_Web_Entities_ClientsTelemetry_ClientsTelemetryResponse
  /// A page of client telemetry.
  public typealias Telemetry =
    Components.Schemas.SkbKontur_Talk_Web_Entities_ClientsTelemetry_ClientsTelemetryResponseV2

  /// Fetches a page of client telemetry for the space with the first-generation endpoint.
  public func telemetryV1(
    from: Date? = nil, to: Date? = nil, take: Int? = nil, pageToken: String? = nil
  ) async throws(KTalkError) -> TelemetryV1 {
    try await call {
      switch try await client.clientsTelemetryGetDomainTelemetryV1(
        .init(
          query: .init(fromDate: from, toDate: to, take: take.map(Int32.init), pageToken: pageToken)
        ))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Fetches a page of client telemetry for the space.
  public func telemetry(
    from: Date? = nil, to: Date? = nil, take: Int? = nil, pageToken: String? = nil
  ) async throws(KTalkError) -> Telemetry {
    try await call {
      switch try await client.clientsTelemetryGetDomainTelemetryV2(
        .init(
          query: .init(fromDate: from, toDate: to, take: take.map(Int32.init), pageToken: pageToken)
        ))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }
}
