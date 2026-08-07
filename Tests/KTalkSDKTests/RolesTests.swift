import Foundation
import OpenAPIRuntime
import Testing

@testable import KTalkSDK

@Suite("Roles")
struct RolesTests {
  private func client(_ transport: any ClientTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  @Test("listRoles decodes an array")
  func listDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "roles-list"))
    let roles = try await client.listRoles()
    #expect(roles.count == 2)
  }

  @Test("role(id:) decodes a role")
  func getDecodes() async throws {
    let client = try client(try ReplayTransport.fixture(named: "role"))
    _ = try await client.role(id: "custom-1")
  }

  @Test("role(id:) maps 404 to notFound")
  func getNotFound() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 404))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.role(id: "gone")
    }
    guard case .notFound(let resource, _) = error else {
      Issue.record("expected .notFound, got \(String(describing: error))")
      return
    }
    #expect(resource == "role")
  }

  @Test("deleteRole maps 403 to forbidden")
  func deleteForbidden() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 403))
    let error = await #expect(throws: KTalkError.self) {
      try await client.deleteRole(id: "custom-1")
    }
    guard case .forbidden = error else {
      Issue.record("expected .forbidden, got \(String(describing: error))")
      return
    }
  }
}
