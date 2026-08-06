import Foundation
import HTTPTypes
import OpenAPIRuntime
import Synchronization

/// A hermetic `ClientTransport` for tests. It records every request and replays a configured
/// response — either an inline synthetic body or a fixture file from `Tests/.../Fixtures`.
///
/// Fixtures are hand-authored synthetic payloads. Never capture responses from a real space.
final class ReplayTransport: ClientTransport, Sendable {
  /// A recorded request with all parameters passed to `send`.
  struct RecordedRequest: Sendable {
    let request: HTTPRequest
    let body: HTTPBody?
    let baseURL: URL
    let operationID: String
  }

  enum ReplayError: Error {
    case fixtureNotFound(String)
  }

  private let handler:
    @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (HTTPResponse, HTTPBody?)
  private let _recordedRequests = Mutex<[RecordedRequest]>([])

  var recordedRequests: [RecordedRequest] {
    _recordedRequests.withLock { $0 }
  }

  /// The most recently recorded request, if any.
  var lastRequest: RecordedRequest? {
    _recordedRequests.withLock { $0.last }
  }

  init(
    handler:
      @escaping @Sendable (HTTPRequest, HTTPBody?, URL, String) async throws -> (
        HTTPResponse, HTTPBody?
      )
  ) {
    self.handler = handler
  }

  /// Replays a fixed status code and optional inline JSON body.
  static func returning(statusCode: Int, body: String? = nil) -> ReplayTransport {
    ReplayTransport { _, _, _, _ in
      var headerFields = HTTPFields()
      if body != nil {
        headerFields[.contentType] = "application/json"
      }
      let response = HTTPResponse(status: .init(code: statusCode), headerFields: headerFields)
      return (response, body.map { HTTPBody($0) })
    }
  }

  /// Replays a fixture file (`Tests/.../Fixtures/<name>.json`) with the given status code.
  static func fixture(named name: String, statusCode: Int = 200) throws -> ReplayTransport {
    let data = try fixtureData(named: name)
    return ReplayTransport { _, _, _, _ in
      var headerFields = HTTPFields()
      headerFields[.contentType] = "application/json"
      let response = HTTPResponse(status: .init(code: statusCode), headerFields: headerFields)
      return (response, HTTPBody(data))
    }
  }

  /// Loads the raw bytes of a synthetic fixture file.
  static func fixtureData(named name: String) throws -> Data {
    guard
      let url = Bundle.module.url(
        forResource: name, withExtension: "json", subdirectory: "Fixtures")
    else {
      throw ReplayError.fixtureNotFound(name)
    }
    return try Data(contentsOf: url)
  }

  func send(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String
  ) async throws -> (HTTPResponse, HTTPBody?) {
    let recorded = RecordedRequest(
      request: request, body: body, baseURL: baseURL, operationID: operationID)
    _recordedRequests.withLock { $0.append(recorded) }
    return try await handler(request, body, baseURL, operationID)
  }
}
