import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk recordings …` — work with conference recordings.
struct Recordings: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "recordings",
    abstract: "Work with conference recordings.",
    discussion: """
      `list` and `get` see every recording in the space. `list-accessible` and \
      `get-accessible` see only the recordings the key's user can open.
      """,
    subcommands: [
      List.self, ListV1.self, Get.self, ListAccessible.self, GetAccessible.self,
      Participants.self, Transcript.self, Summary.self, SummaryByType.self, Artifacts.self,
      Download.self, Current.self, Start.self, Edit.self, Delete.self, Access.self,
      SetAccess.self, SetImmutable.self, UnsetImmutable.self,
    ]
  )
}

extension Recordings {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list", abstract: "[space key] List every recording in the space.")

    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Page cursor from a previous response's nextPageToken.")
    var pageToken: String?
    @Option(name: .long, help: "Maximum number of recordings to return.")
    var limit: Int?
    @Option(name: .long, help: "Full-text query.")
    var query: String?
    @Flag(name: .long, help: "Fetch every page and print a flat array.")
    var all = false

    func run() async throws {
      let client = try global.makeClient()
      if all {
        let items = try await client.collectAll {
          (token) throws(KTalkError) -> Page<KTalkClient.Recording> in
          try await client.listRecordings(pageToken: token, limit: limit, query: query)
        }
        try printJSON(items)
      } else {
        let page = try await client.listRecordings(
          pageToken: pageToken, limit: limit, query: query)
        try printJSON(page)
      }
    }
  }

  struct Get: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "get", abstract: "[space key] Get any recording in the space by key.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String

    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.recording(key: key))
    }
  }

  struct ListAccessible: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list-accessible",
      abstract: "[personal key] List the recordings you can open, newest first.")

    @OptionGroup var global: GlobalOptions
    @Option(
      name: .long,
      help: "Page size, 1 to \(KTalkClient.accessibleRecordingsMaxPageSize) (server default: 10).")
    var top: Int?
    @Option(name: .long, help: "Skip N recordings.") var skip: Int?
    @Flag(name: .long, help: "Fetch every page and print a flat array.")
    var all = false

    func validate() throws {
      let max = KTalkClient.accessibleRecordingsMaxPageSize
      if let top, !(1...max).contains(top) {
        throw ValidationError("--top must be between 1 and \(max).")
      }
      if let skip, skip < 0 {
        throw ValidationError("--skip must not be negative.")
      }
      if all, top != nil || skip != nil {
        throw ValidationError("--all fetches every page itself; drop --top and --skip.")
      }
    }

    func run() async throws {
      let client = try global.makeClient()
      if all {
        try printJSON(try await client.allAccessibleRecordings())
      } else {
        try printJSON(try await client.listAccessibleRecordings(top: top, skip: skip))
      }
    }
  }

  struct GetAccessible: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "get-accessible", abstract: "[personal key] Get a recording you can open by key."
    )

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String

    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.accessibleRecording(key: key))
    }
  }

  /// Output format for the transcript command.
  enum TranscriptFormat: String, CaseIterable, ExpressibleByArgument {
    case json
    case text
  }

  struct Transcript: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "transcript", abstract: "[personal key] Get a recording's transcript.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String
    @Option(name: .long, help: "Output format: json (default) or text (speaker dialogue).")
    var format: TranscriptFormat = .json
    @Flag(name: .long, help: "Omit timestamps in text output.")
    var noTimestamps = false

    func run() async throws {
      let client = try global.makeClient()
      let transcript = try await client.recordingTranscript(key: key)
      switch format {
      case .json:
        try printJSON(transcript)
      case .text:
        print(transcript.dialogue(includeTimestamps: !noTimestamps))
      }
    }
  }

  struct Summary: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "summary", abstract: "[personal key] Get a recording's summary / protocol.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String

    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.recordingSummary(key: key))
    }
  }

  struct Download: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "download", abstract: "[space key] Download a recording's media file.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String
    @Option(name: .long, help: "Quality name (e.g. source).") var quality: String = "source"
    @Option(name: [.customShort("o"), .long], help: "Output file path.") var output: String

    func run() async throws {
      let client = try global.makeClient()
      let data = try await client.downloadRecording(key: key, quality: quality)
      try data.write(to: URL(fileURLWithPath: output))
      try printJSON(
        DownloadResult(recordingKey: key, quality: quality, bytes: data.count, path: output))
    }

    private struct DownloadResult: Encodable {
      let recordingKey: String
      let quality: String
      let bytes: Int
      let path: String
    }
  }

  struct ListV1: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list-v1",
      abstract:
        "[space key] List space recordings with the first-generation endpoint, paged by skip/top.")

    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Recordings started at or after this date (ISO 8601).")
    var startFrom: String?
    @Option(name: .long, help: "Recordings started at or before this date (ISO 8601).")
    var startTo: String?
    @Option(name: .long, help: "Skip N recordings.") var skip: Int?
    @Option(name: .long, help: "Page size (server default: 30).") var top: Int?
    @Option(name: .long, help: "Full-text query.") var query: String?
    @Option(name: .long, help: "Title filter.") var title: String?
    @Option(name: .long, help: "How many participants to include per recording.")
    var maxParticipantCount: Int?
    @Option(name: .long, help: "Sort order, e.g. byTimeNewFirst.") var orderMode: String?

    func run() async throws {
      let client = try global.makeClient()
      try printJSON(
        try await client.listRecordingsV1(
          startFrom: try startFrom.map(parseISODate), startTo: try startTo.map(parseISODate),
          skip: skip, top: top, query: query, title: title,
          maxParticipantCount: maxParticipantCount,
          orderMode: try orderMode.map {
            try parseChoice($0, as: KTalkClient.RecordingsOrderMode.self)
          }
        ))
    }
  }

  struct Participants: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "participants", abstract: "[space key] List a recording's participants.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String
    @Option(name: .long, help: "Skip N participants.") var skip: Int?
    @Option(name: .long, help: "Page size.") var top: Int?

    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.recordingParticipants(key: key, skip: skip, top: top))
    }
  }

  struct SummaryByType: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "summary-by-type",
      abstract: "[personal key] Get one kind of a recording's summary: shortSummary or protocol.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String
    @Argument(help: "Summary kind: shortSummary or protocol.") var type: String

    func run() async throws {
      let client = try global.makeClient()
      let kind = try parseChoice(type, as: KTalkClient.SummaryType.self)
      try printJSON(try await client.recordingSummaryByType(key: key, type: kind))
    }
  }

  struct Artifacts: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "artifacts",
      abstract:
        "[personal key] Get a recording's transcript, short summary and protocol in one request.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String

    func run() async throws {
      try printJSON(try await global.makeClient().recordingArtifacts(key: key))
    }
  }

  struct Current: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "current", abstract: "[space key] Get the recording currently running in a room."
    )

    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Room name.") var room: String
    @Option(name: .long, help: "Session hall, for rooms that have several.") var sessionHall:
      String?

    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.activeRecording(roomName: room, sessionHall: sessionHall))
    }
  }

  struct Start: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "start", abstract: "Start recording a conference from a JSON file.")

    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON StartRecordingParams file.") var fromJSON: String

    func run() async throws {
      let params = try decodeJSON(KTalkClient.StartRecordingParams.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().startRecording(params))
    }
  }

  struct Edit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "edit", abstract: "Edit a recording's title and description from a JSON file.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String
    @Option(name: .long, help: "Path to a JSON RecordingUpdateParams file.") var fromJSON: String

    func run() async throws {
      let params = try decodeJSON(KTalkClient.RecordingUpdateParams.self, fromFile: fromJSON)
      try await global.makeClient().editRecording(key: key, params: params)
      try printJSON(["recording": key, "action": "edit"])
    }
  }

  struct Delete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete", abstract: "Delete a recording.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String
    @Flag(name: .long, help: "Delete even a protected (immutable) recording.") var force = false

    func run() async throws {
      try await global.makeClient().deleteRecording(key: key, force: force ? true : nil)
      try printJSON(["recording": key, "action": "delete"])
    }
  }

  struct Access: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "access", abstract: "[space key] Get who can open a recording.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String

    func run() async throws {
      try printJSON(try await global.makeClient().recordingAccess(key: key))
    }
  }

  struct SetAccess: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "set-access", abstract: "Change who can open a recording from a JSON file.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String
    @Option(name: .long, help: "Path to a JSON RecordingAccessPatch file.") var fromJSON: String

    func run() async throws {
      let patch = try decodeJSON(KTalkClient.RecordingAccessPatch.self, fromFile: fromJSON)
      try await global.makeClient().updateRecordingAccess(key: key, patch: patch)
      try printJSON(["recording": key, "action": "set-access"])
    }
  }

  struct SetImmutable: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "set-immutable", abstract: "Protect a recording from deletion.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String

    func run() async throws {
      try await global.makeClient().setRecordingImmutable(key: key)
      try printJSON(["recording": key, "action": "set-immutable"])
    }
  }

  struct UnsetImmutable: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "unset-immutable", abstract: "Remove a recording's deletion protection.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String

    func run() async throws {
      try await global.makeClient().unsetRecordingImmutable(key: key)
      try printJSON(["recording": key, "action": "unset-immutable"])
    }
  }
}
