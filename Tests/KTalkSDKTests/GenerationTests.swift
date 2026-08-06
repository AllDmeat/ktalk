import Testing

@testable import KTalkSDK

/// Verifies the OpenAPI generator produced a usable client. These references only compile if
/// `swift-openapi-generator` emitted the `Client` type and the `APIProtocol` it conforms to.
@Suite("Generation")
struct GenerationTests {
  @Test("Generated Client conforms to the generated APIProtocol")
  func generatedClientExists() {
    let clientType: any APIProtocol.Type = Client.self
    #expect(String(describing: clientType) == "Client")
  }
}
