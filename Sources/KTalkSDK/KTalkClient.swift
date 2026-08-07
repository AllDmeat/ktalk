import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

/// The main entry point for the KTalk SDK.
///
/// A `KTalkClient` targets a single Kontur.Talk space. Authentication uses an admin-issued
/// API key sent in the `X-Auth-Token` header. Requests are retried on transient failures and
/// rate limits.
public struct KTalkClient: Sendable {
  /// The generated OpenAPI client, used by the per-tag facade extensions.
  let client: Client

  /// Creates a client for a Kontur.Talk space.
  ///
  /// - Parameters:
  ///   - baseURL: The space base URL, e.g. `https://example.ktalk.ru`. Must be HTTPS.
  ///   - token: The `X-Auth-Token` API key.
  ///   - transport: The HTTP transport. Defaults to `URLSessionTransport()`; pass a custom
  ///     transport (for example a replay transport) in tests.
  /// - Throws: ``KTalkError/invalidURL(_:)`` if `baseURL` is not a valid HTTPS URL.
  public init(
    baseURL: String,
    token: String,
    transport: any ClientTransport = URLSessionTransport()
  ) throws(KTalkError) {
    guard let url = URL(string: baseURL), url.scheme?.lowercased() == "https" else {
      throw KTalkError.invalidURL(baseURL)
    }
    let gate = RateLimitGate()
    self.client = Client(
      serverURL: url,
      configuration: Configuration(dateTranscoder: LenientISO8601DateTranscoder()),
      transport: transport,
      middlewares: [
        AuthenticationMiddleware(token: token),
        RetryMiddleware(gate: gate),
      ]
    )
  }

  // MARK: - Error mapping helpers

  /// Runs an operation, translating any non-``KTalkError`` failure into a ``KTalkError``.
  ///
  /// Transient failures (429/5xx/network) are already surfaced as ``KTalkError`` by
  /// ``RetryMiddleware``; this catches the remainder — decoding failures and other client
  /// errors thrown while parsing a response.
  func call<T>(_ operation: () async throws -> T) async throws(KTalkError) -> T {
    do {
      return try await operation()
    } catch let error as KTalkError {
      throw error
    } catch let error as ClientError {
      // A middleware (e.g. RetryMiddleware) may throw a KTalkError that the generated client
      // wraps in a ClientError; unwrap it so the typed error survives.
      if let ktalkError = error.underlyingError as? KTalkError {
        throw ktalkError
      }
      if error.underlyingError is DecodingError {
        throw .decodingError(underlying: error)
      }
      throw .networkError(underlying: error)
    } catch {
      throw .networkError(underlying: error)
    }
  }

  /// Decodes a value, wrapping any failure into ``KTalkError/decodingError(underlying:)``.
  func decode<T>(_ extract: () throws -> T) throws(KTalkError) -> T {
    do {
      return try extract()
    } catch {
      throw .decodingError(underlying: error)
    }
  }

  /// Maps an undocumented HTTP status code into a ``KTalkError``.
  ///
  /// Facade methods that receive a 404 should instead throw
  /// ``KTalkError/notFound(resource:identifier:)`` with the concrete resource they looked up.
  func statusError(statusCode: Int, body: String?) -> KTalkError {
    switch statusCode {
    case 401: .unauthorized
    case 403: .forbidden
    case 500...599: .serverError(statusCode: statusCode, body: body)
    default: .unexpectedResponse(statusCode: statusCode, body: body)
    }
  }

  /// Maps a 404 to ``KTalkError/notFound(resource:identifier:)`` and any other status to a
  /// generic status error. Used by facade methods that looked up a concrete resource.
  func notFoundOrStatus(_ statusCode: Int, resource: String, identifier: String) -> KTalkError {
    statusCode == 404
      ? .notFound(resource: resource, identifier: identifier)
      : statusError(statusCode: statusCode, body: nil)
  }
}
