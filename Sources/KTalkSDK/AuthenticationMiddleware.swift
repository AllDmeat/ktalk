import Foundation
import HTTPTypes
import OpenAPIRuntime

/// A middleware that injects the `X-Auth-Token` header into every outgoing request.
///
/// Kontur.Talk authenticates integrator requests with an admin-issued API key sent in the
/// `X-Auth-Token` header.
struct AuthenticationMiddleware: ClientMiddleware {
  /// The `X-Auth-Token` header name. The literal is a valid token, so the force unwrap
  /// never triggers.
  // swift-format-ignore: NeverForceUnwrap
  static let headerName = HTTPField.Name("X-Auth-Token")!

  private let token: String

  init(token: String) {
    self.token = token
  }

  func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    var request = request
    request.headerFields[Self.headerName] = token
    return try await next(request, body, baseURL)
  }
}
