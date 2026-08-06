import Foundation
import OpenAPIRuntime

/// A date transcoder that tolerates the ISO 8601 variants Kontur.Talk returns.
///
/// The API emits timestamps both with fractional seconds (`2026-01-02T03:04:05.678Z`) and
/// without (`2026-01-02T03:04:05Z`). The runtime's default transcoder accepts only one form,
/// so decoding fails on the other. This transcoder parses either and encodes with fractional
/// seconds. `Date.ISO8601FormatStyle` is a `Sendable` value type, so instances are created per
/// call without shared mutable formatter state.
struct LenientISO8601DateTranscoder: DateTranscoder {
  func encode(_ date: Date) throws -> String {
    Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(date)
  }

  func decode(_ string: String) throws -> Date {
    if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string) {
      return date
    }
    if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: false).parse(string) {
      return date
    }
    throw DecodingError.dataCorrupted(
      .init(codingPath: [], debugDescription: "Expected an ISO 8601 date, got '\(string)'"))
  }
}
