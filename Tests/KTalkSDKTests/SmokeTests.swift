import Testing

@testable import KTalkSDK

@Suite("Smoke")
struct SmokeTests {
  @Test("SDK exposes a version string")
  func exposesVersion() {
    #expect(!KTalkSDK.version.isEmpty)
  }
}
