import Foundation
import HTTPTypes
import Synchronization
import Testing

@testable import KTalkSDK

@Suite("Middleware")
struct MiddlewareTests {
  private let baseURL = URL(string: "https://example.ktalk.ru")!

  private func request(_ method: HTTPRequest.Method) -> HTTPRequest {
    HTTPRequest(
      method: method, scheme: "https", authority: "example.ktalk.ru", path: "/api/Rooms/demo")
  }

  @Test("AuthenticationMiddleware injects the X-Auth-Token header")
  func injectsAuthToken() async throws {
    let middleware = AuthenticationMiddleware(token: "test-token")
    let seen = Mutex<HTTPRequest?>(nil)

    _ = try await middleware.intercept(
      request(.get), body: nil, baseURL: baseURL, operationID: "op"
    ) { request, _, _ in
      seen.withLock { $0 = request }
      return (HTTPResponse(status: .ok), nil)
    }

    #expect(seen.withLock { $0 }?.headerFields[AuthenticationMiddleware.headerName] == "test-token")
  }

  @Test("RetryMiddleware retries 5xx for idempotent methods then throws serverError")
  func retriesServerErrorsOnGet() async throws {
    let calls = Mutex(0)
    let middleware = RetryMiddleware(maxAttempts: 3, baseDelay: 0.001, maxDelay: 0.01)

    let error = await #expect(throws: KTalkError.self) {
      _ = try await middleware.intercept(
        request(.get), body: nil, baseURL: baseURL, operationID: "op"
      ) { _, _, _ in
        calls.withLock { $0 += 1 }
        return (HTTPResponse(status: .init(code: 503)), nil)
      }
    }

    #expect(calls.withLock { $0 } == 3)
    guard case .serverError(let code, _) = error else {
      Issue.record("expected serverError, got \(String(describing: error))")
      return
    }
    #expect(code == 503)
  }

  @Test("RetryMiddleware does not retry 5xx for non-idempotent methods")
  func doesNotRetryServerErrorsOnPost() async throws {
    let calls = Mutex(0)
    let middleware = RetryMiddleware(maxAttempts: 3, baseDelay: 0.001, maxDelay: 0.01)

    let error = await #expect(throws: KTalkError.self) {
      _ = try await middleware.intercept(
        request(.post), body: nil, baseURL: baseURL, operationID: "op"
      ) { _, _, _ in
        calls.withLock { $0 += 1 }
        return (HTTPResponse(status: .init(code: 500)), nil)
      }
    }

    #expect(calls.withLock { $0 } == 1)
    guard case .serverError(let code, _) = error else {
      Issue.record("expected serverError, got \(String(describing: error))")
      return
    }
    #expect(code == 500)
  }

  @Test("RetryMiddleware passes 4xx responses through unchanged")
  func passesThroughClientErrors() async throws {
    let calls = Mutex(0)
    let middleware = RetryMiddleware(maxAttempts: 3, baseDelay: 0.001, maxDelay: 0.01)

    let (response, _) = try await middleware.intercept(
      request(.get), body: nil, baseURL: baseURL, operationID: "op"
    ) { _, _, _ in
      calls.withLock { $0 += 1 }
      return (HTTPResponse(status: .init(code: 403)), nil)
    }

    #expect(response.status.code == 403)
    #expect(calls.withLock { $0 } == 1)
  }
}
