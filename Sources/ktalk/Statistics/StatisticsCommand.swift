import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk stats …` — domain statistics.
struct Stats: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "stats",
    abstract: "Domain statistics.",
    subcommands: [
      Domain.self, RegisteredUsers.self, Conferences.self, Recordings.self, Kiosks.self,
      Online.self, ConferencesOnline.self, RecordingsOnline.self, KiosksOnline.self,
      StreamsOnline.self, TotalRecordingsSize.self, Whiteboards.self, DeepFake.self, Tariff.self,
    ]
  )
}

/// A start/end date window shared by several stats commands.
struct StatsWindow: ParsableArguments {
  @Option(name: .long, help: "Start date (ISO 8601).") var start: String?
  @Option(name: .long, help: "End date (ISO 8601).") var end: String?
  func dates() throws -> (Date?, Date?) {
    (try start.map(parseISODate), try end.map(parseISODate))
  }
}

extension Stats {
  struct Domain: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "domain", abstract: "Active-user statistics for a window.")
    @OptionGroup var global: GlobalOptions
    @OptionGroup var window: StatsWindow
    func run() async throws {
      let (start, end) = try window.dates()
      try printJSON(try await global.makeClient().domainStatistics(start: start, end: end))
    }
  }

  struct RegisteredUsers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "registered-users", abstract: "Registered-user statistics.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      try printJSON(try await global.makeClient().registeredUsersStatistics())
    }
  }

  struct Conferences: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "conferences", abstract: "Conference statistics for a window.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "From date (ISO 8601).") var from: String?
    @Option(name: .long, help: "To date (ISO 8601).") var to: String?
    func run() async throws {
      try printJSON(
        try await global.makeClient().conferenceStatistics(
          fromDate: try from.map(parseISODate), toDate: try to.map(parseISODate)))
    }
  }

  struct Recordings: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "recordings", abstract: "Recording statistics for a window.")
    @OptionGroup var global: GlobalOptions
    @OptionGroup var window: StatsWindow
    func run() async throws {
      let (start, end) = try window.dates()
      try printJSON(try await global.makeClient().recordingsStatistics(start: start, end: end))
    }
  }

  struct Kiosks: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "kiosks", abstract: "Kiosk statistics for a window.")
    @OptionGroup var global: GlobalOptions
    @OptionGroup var window: StatsWindow
    func run() async throws {
      let (start, end) = try window.dates()
      try printJSON(try await global.makeClient().kioskStatistics(start: start, end: end))
    }
  }

  struct Online: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "online", abstract: "Live online counters.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().onlineCounters()) }
  }

  struct ConferencesOnline: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "conferences-online", abstract: "Online conference statistics.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().conferencesOnline()) }
  }

  struct RecordingsOnline: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "recordings-online", abstract: "Online recording statistics.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().recordingsOnline()) }
  }

  struct KiosksOnline: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "kiosks-online", abstract: "Online kiosk statistics.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().kiosksOnline()) }
  }

  struct StreamsOnline: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "streams-online", abstract: "Online stream statistics.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().streamsOnline()) }
  }

  struct TotalRecordingsSize: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "recordings-size", abstract: "Total recording-size statistics.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().totalRecordingsSize()) }
  }

  struct Whiteboards: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "whiteboards", abstract: "Whiteboard statistics.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().whiteboardsStatistics()) }
  }

  struct DeepFake: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "deepfake", abstract: "Deepfake-detection statistics.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().deepFakeStatistics()) }
  }

  struct Tariff: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "tariff", abstract: "Tariff expiration date.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      let date = try await global.makeClient().tariffExpirationDate()
      try printJSON(["tariffExpirationDate": date.map { ISO8601DateFormatter().string(from: $0) }])
    }
  }
}
