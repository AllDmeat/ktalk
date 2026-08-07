import Foundation
import OpenAPIRuntime
import Testing

@testable import KTalkSDK

@Suite("Surveys")
struct SurveysTests {
  private func client(_ transport: any ClientTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  @Test("survey(id:) maps 404 to notFound")
  func getNotFound() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 404))
    let error = await #expect(throws: KTalkError.self) { _ = try await client.survey(id: "gone") }
    guard case .notFound(let resource, _) = error else {
      Issue.record("expected .notFound")
      return
    }
    #expect(resource == "survey")
  }

  @Test("publishSurvey maps 403 to forbidden")
  func publishForbidden() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 403))
    let error = await #expect(throws: KTalkError.self) {
      _ = try await client.publishSurvey(id: "survey-1")
    }
    guard case .forbidden = error else {
      Issue.record("expected .forbidden")
      return
    }
  }
}
