import Foundation

/// Errors thrown by the KTalk SDK.
public enum KTalkError: Error, Sendable {
  /// The provided base URL is invalid (missing, malformed, or not HTTPS).
  case invalidURL(String)
  /// The API returned 401 Unauthorized — the token is missing or invalid.
  case unauthorized
  /// The API returned 403 Forbidden — the token lacks the required scope.
  case forbidden
  /// The requested resource was not found (404).
  case notFound(resource: String, identifier: String)
  /// The API rate limit was exceeded (429).
  case rateLimited(retryAfter: TimeInterval?)
  /// The server returned a 5xx error.
  case serverError(statusCode: Int, body: String?)
  /// A network-level error occurred.
  case networkError(underlying: any Error)
  /// A decoding error occurred while parsing the response.
  case decodingError(underlying: any Error)
  /// The API returned an unexpected HTTP status code.
  case unexpectedResponse(statusCode: Int, body: String?)
}

// MARK: - LocalizedError

extension KTalkError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .invalidURL(let url):
      "Invalid base URL: \(url)"
    case .unauthorized:
      "Unauthorized – check your X-Auth-Token"
    case .forbidden:
      "Forbidden – the token lacks the required scope"
    case .notFound(let resource, let identifier):
      "\(resource) '\(identifier)' not found"
    case .rateLimited(let retryAfter):
      if let retryAfter {
        "Rate limited – retry after \(Int(retryAfter))s"
      } else {
        "Rate limited – retry later"
      }
    case .serverError(let statusCode, let body):
      "Server error \(statusCode)" + (body.map { ": \($0)" } ?? "")
    case .networkError(let underlying):
      "Network error: \(underlying.localizedDescription)"
    case .decodingError(let underlying):
      "Decoding error: \(underlying.localizedDescription)"
    case .unexpectedResponse(let statusCode, let body):
      "Unexpected HTTP response: \(statusCode)" + (body.map { ": \($0)" } ?? "")
    }
  }
}
