import Foundation
import OpenAPIRuntime
import Testing

@testable import KTalkSDK

@Suite("Users")
struct UsersTests {
  private func client(_ transport: any ClientTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  @Test("searchUsers decodes the result")
  func searchDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "users-search"))
    let result = try await client.searchUsers(query: "user")
    #expect(result.users?.count == 1)
    #expect(result.users?.first?.email == "user@example.com")
  }

  @Test("user(key:) decodes a user")
  func getDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "user"))
    let user = try await client.user(key: "user-1")
    #expect(user.email == "user@example.com")
  }

  @Test("user(key:) maps 404 to notFound")
  func getNotFound() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 404))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.user(key: "gone")
    }
    guard case .notFound(let resource, _) = error else {
      Issue.record("expected .notFound, got \(String(describing: error))")
      return
    }
    #expect(resource == "user")
  }

  @Test("userRoles decodes an array of role refs")
  func rolesDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "user-roles"))
    let roles = try await client.userRoles(userKey: "user-1")
    #expect(roles.first?.roleId == "user")
  }

  @Test("deleteUser succeeds on 200 and maps 403")
  func delete() async throws {
    let ok = try client(ReplayTransport.returning(statusCode: 200))
    try await ok.deleteUser(key: "user-1")

    let denied = try client(ReplayTransport.returning(statusCode: 403))
    let error = await #expect(throws: KTalkError.self) {
      try await denied.deleteUser(key: "user-1")
    }
    guard case .forbidden = error else {
      Issue.record("expected .forbidden, got \(String(describing: error))")
      return
    }
  }
}
