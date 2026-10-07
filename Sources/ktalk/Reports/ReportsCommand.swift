import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk reports …` — audit log, conference history, and reports.
struct Reports: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "reports",
    abstract: "Audit log, conference history, and reports.",
    subcommands: [
      AuditLogCommand.self, Conferences.self, Conference.self, ConferenceEnriched.self,
      Participants.self, Activity.self, Chat.self, Room.self, Questions.self, Attendance.self,
    ]
  )
}

extension Reports {
  struct AuditLogCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "audit-log", abstract: "[space key] Fetch the audit log for a time window.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Start time (ISO 8601).") var start: String
    @Option(name: .long, help: "End time (ISO 8601).") var end: String
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(
        try await client.auditLog(
          startTime: try parseISODate(start), endTime: try parseISODate(end)))
    }
  }

  struct Conferences: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "conferences", abstract: "[space key] List past conferences.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "From date (ISO 8601).") var from: String?
    @Option(name: .long, help: "To date (ISO 8601).") var to: String?
    @Option(name: .long, help: "Skip N.") var skip: Int?
    @Option(name: .long, help: "Take N.") var take: Int?
    @Option(name: .long, help: "Filter by room name (repeatable).") var room: [String] = []
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(
        try await client.conferences(
          fromDate: try from.map(parseISODate), toDate: try to.map(parseISODate),
          skip: skip, take: take, roomNames: room.isEmpty ? nil : room))
    }
  }

  struct Conference: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "conference", abstract: "[space key] Get a past conference's metadata.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Conference key.") var key: String
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.conference(key: key))
    }
  }

  struct ConferenceEnriched: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "conference-enriched",
      abstract: "[space key] Get a conference's enriched artifacts.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Conference key.") var key: String
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.enrichedConference(key: key))
    }
  }

  struct Participants: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "participants", abstract: "[space key] Get a conference's participants report.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Conference key.") var key: String
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.conferenceParticipants(key: key))
    }
  }

  struct Activity: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "activity", abstract: "[space key] Get a conference's activity report.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Conference key.") var key: String
    @Option(name: .long, help: "Skip N.") var skip: Int?
    @Option(name: .long, help: "Take N.") var take: Int?
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.conferenceActivity(key: key, skip: skip, take: take))
    }
  }

  struct Chat: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "chat", abstract: "[space key] Get a conference's chat report.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Conference key.") var key: String
    @Option(name: .long, help: "Skip N.") var skip: Int?
    @Option(name: .long, help: "Take N.") var take: Int?
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.conferenceChat(key: key, skip: skip, take: take))
    }
  }

  struct Room: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "room", abstract: "[space key] Get a room statistics report.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Option(name: .long, help: "From date (ISO 8601).") var from: String
    @Option(name: .long, help: "To date (ISO 8601).") var to: String?
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(
        try await client.roomReport(
          roomName: name, from: try parseISODate(from), to: try to.map(parseISODate)))
    }
  }

  struct Questions: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "questions",
      abstract: "[space key] Download the questions from a conference's chat as an Excel file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Conference key.") var key: String
    @Option(name: [.customShort("o"), .long], help: "Output file path.") var output: String
    func run() async throws {
      try saveDownload(
        try await global.makeClient().conferenceQuestionsReport(key: key), to: output)
    }
  }

  struct Attendance: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "attendance",
      abstract: "[space key] Download the space attendance report for a period as an Excel file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Period start (ISO 8601).") var from: String
    @Option(name: .long, help: "Period end (ISO 8601).") var to: String?
    @Option(name: [.customShort("o"), .long], help: "Output file path.") var output: String
    func run() async throws {
      let data = try await global.makeClient().attendanceReport(
        from: try parseISODate(from), to: try to.map(parseISODate))
      try saveDownload(data, to: output)
    }
  }
}
