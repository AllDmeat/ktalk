import ArgumentParser
import KTalkSDK

/// `ktalk telemetry …` — read client telemetry of the space.
struct TelemetryCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "telemetry",
    abstract: "Read client telemetry of the space.",
    subcommands: [List.self, ListV1.self]
  )
}

extension TelemetryCommand {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list", abstract: "[space key] Get a page of client telemetry.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Period start (ISO 8601).") var from: String?
    @Option(name: .long, help: "Period end (ISO 8601).") var to: String?
    @Option(name: .long, help: "Page size.") var take: Int?
    @Option(name: .long, help: "Page cursor from a previous response.") var pageToken: String?
    func validate() throws {
      try checkRange(take, "--take", 1...1000)
    }

    func run() async throws {
      try printJSON(
        try await global.makeClient().telemetry(
          from: try from.map(parseISODate), to: try to.map(parseISODate), take: take,
          pageToken: pageToken))
    }
  }

  struct ListV1: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list-v1",
      abstract: "[space key] Get a page of client telemetry with the first-generation endpoint.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Period start (ISO 8601).") var from: String?
    @Option(name: .long, help: "Period end (ISO 8601).") var to: String?
    @Option(name: .long, help: "Page size.") var take: Int?
    @Option(name: .long, help: "Page cursor from a previous response.") var pageToken: String?
    func validate() throws {
      try checkRange(take, "--take", 1...1000)
    }

    func run() async throws {
      try printJSON(
        try await global.makeClient().telemetryV1(
          from: try from.map(parseISODate), to: try to.map(parseISODate), take: take,
          pageToken: pageToken))
    }
  }
}
