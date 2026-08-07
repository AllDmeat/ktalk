import Foundation
import Testing

@testable import KTalkSDK

@Suite("Transcript dialogue")
struct TranscriptDialogueTests {
  private func loadTranscript() throws -> KTalkClient.RecordingTranscript {
    let data = try ReplayTransport.fixtureData(named: "transcript-dialogue")
    return try JSONDecoder().decode(KTalkClient.RecordingTranscript.self, from: data)
  }

  @Test("renders speakers interleaved by time with timestamps")
  func rendersDialogue() throws {
    let dialogue = try loadTranscript().dialogue()
    #expect(
      dialogue == """
        [00:00] Alice: Hello.
        [00:02] Bob: Hi Alice.
        [00:04] Alice: How are you?
        """)
  }

  @Test("can omit timestamps")
  func withoutTimestamps() throws {
    let dialogue = try loadTranscript().dialogue(includeTimestamps: false)
    #expect(dialogue == "Alice: Hello.\nBob: Hi Alice.\nAlice: How are you?")
  }
}
