import Foundation

extension Components.Schemas.SkbKontur_Talk_SpeechCore_Api_Models_Transcription_TalkTranscript {
  /// Renders the transcript as a plain-text, speaker-by-speaker dialogue ordered by time.
  ///
  /// Each track holds one speaker's chunks; this interleaves all chunks by their start offset,
  /// merges consecutive turns by the same speaker, and prefixes each turn with a `mm:ss`
  /// timestamp (unless `includeTimestamps` is `false`).
  ///
  /// Speaker names come from the transcript's `TalkUserRef`. The published schema exposes the
  /// first name and patronymic (not the surname), so named speakers appear by first name.
  public func dialogue(includeTimestamps: Bool = true) -> String {
    struct Utterance {
      let start: Int
      let speaker: String
      let text: String
    }

    var utterances: [Utterance] = []
    for track in tracks ?? [] {
      let name = Self.speakerName(track.speaker)
      for chunk in track.chunks ?? [] {
        let text = (chunk.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { continue }
        utterances.append(
          Utterance(start: Int(chunk.startTimeOffsetInMillis ?? 0), speaker: name, text: text))
      }
    }
    utterances.sort { $0.start < $1.start }

    var lines: [String] = []
    var currentSpeaker: String?
    var buffer: [String] = []
    var turnStart = 0

    func flush() {
      guard let speaker = currentSpeaker, !buffer.isEmpty else { return }
      let prefix = includeTimestamps ? "[\(Self.timestamp(turnStart))] " : ""
      lines.append("\(prefix)\(speaker): \(buffer.joined(separator: " "))")
    }

    for utterance in utterances {
      if utterance.speaker != currentSpeaker {
        flush()
        currentSpeaker = utterance.speaker
        buffer = []
        turnStart = utterance.start
      }
      buffer.append(utterance.text)
    }
    flush()

    return lines.joined(separator: "\n")
  }

  private static func speakerName(
    _ ref: Components.Schemas.SkbKontur_Talk_Users_Api_Models_TalkUserRef?
  ) -> String {
    if let info = ref?.userInfo {
      let name = [info.firstname, info.patronymic]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " ")
      if !name.isEmpty { return name }
      if let login = info.login, !login.isEmpty { return login }
      if let email = info.email, !email.isEmpty { return email }
    }
    if let anonymous = ref?.anonymousName, !anonymous.isEmpty { return anonymous }
    return "Speaker"
  }

  private static func timestamp(_ milliseconds: Int) -> String {
    let totalSeconds = max(0, milliseconds) / 1000
    return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
  }
}
