import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk recordings …` — work with conference recordings.
struct Recordings: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "recordings",
    abstract: "Work with conference recordings.",
    subcommands: [List.self, Get.self, Transcript.self, Summary.self, Download.self]
  )
}

extension Recordings {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list", abstract: "List recordings.")

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
      commandName: "get", abstract: "Get a recording by key.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String

    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.recording(key: key))
    }
  }

  struct Transcript: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "transcript", abstract: "Get a recording's transcript.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String

    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.recordingTranscript(key: key))
    }
  }

  struct Summary: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "summary", abstract: "Get a recording's summary / protocol.")

    @OptionGroup var global: GlobalOptions
    @Argument(help: "Recording key.") var key: String

    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.recordingSummary(key: key))
    }
  }

  struct Download: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "download", abstract: "Download a recording's media file.")

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
}
