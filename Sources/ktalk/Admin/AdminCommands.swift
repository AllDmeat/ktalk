import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk calendar-servers …` — manage additional calendar servers.
struct CalendarServers: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "calendar-servers",
    abstract: "Manage additional calendar servers.",
    subcommands: [List.self, Get.self, Add.self, Update.self, Delete.self]
  )
}

extension CalendarServers {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list", abstract: "[space key] List calendar servers.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Skip N.") var skip: Int?
    @Option(name: .long, help: "Take N.") var take: Int?
    func validate() throws {
      try checkRange(skip, "--skip", 0...int32Max)
      try checkRange(take, "--take", 0...int32Max)
    }

    func run() async throws {
      try printJSON(try await global.makeClient().calendarServers(skip: skip, take: take))
    }
  }

  struct Get: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "get", abstract: "[space key] Get a calendar server by id.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Calendar server id.") var id: String
    func run() async throws { try printJSON(try await global.makeClient().calendarServer(id: id)) }
  }

  struct Add: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "add", abstract: "Add a calendar server from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON CalendarServerCreate file.") var fromJSON: String
    func run() async throws {
      let model = try decodeJSON(KTalkClient.CalendarServerCreate.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().addCalendarServer(model))
    }
  }

  struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "update", abstract: "Update a calendar server from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Calendar server id.") var id: String
    @Option(name: .long, help: "Path to a JSON CalendarServerUpdate file.") var fromJSON: String
    func run() async throws {
      let model = try decodeJSON(KTalkClient.CalendarServerUpdate.self, fromFile: fromJSON)
      try await global.makeClient().updateCalendarServer(id: id, model: model)
      try printJSON(["calendarServer": id, "action": "update"])
    }
  }

  struct Delete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete", abstract: "Delete a calendar server.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Calendar server id.") var id: String
    func run() async throws {
      try await global.makeClient().deleteCalendarServer(id: id)
      try printJSON(["calendarServer": id, "action": "delete"])
    }
  }
}

/// `ktalk deepfake …` — deepfake-detection reports and statistics.
struct DeepFake: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "deepfake",
    abstract: "Deepfake-detection reports and statistics.",
    subcommands: [Report.self, Statistic.self, TaskFile.self, TaskFiles.self]
  )
}

extension DeepFake {
  struct Report: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "report", abstract: "[space key] Get the deepfake report for a conference.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Conference key.") var conferenceKey: String
    @Option(name: .long, help: "Timezone.") var timezone: String?
    func run() async throws {
      try printJSON(
        try await global.makeClient().deepFakeReport(
          conferenceKey: conferenceKey, timezone: timezone))
    }
  }

  struct Statistic: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "statistic", abstract: "[space key] Get deepfake-detection statistics.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      try printJSON(try await global.makeClient().deepFakeDetectionStatistic())
    }
  }
  struct TaskFile: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "task-file",
      abstract: "[space key] Download the reference file of a detection task.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Conference key.") var conferenceKey: String
    @Argument(help: "Task key.") var taskKey: String
    @Option(name: [.customShort("o"), .long], help: "Output file path.") var output: String
    func run() async throws {
      let data = try await global.makeClient().deepFakeTaskFile(
        conferenceKey: conferenceKey, taskKey: taskKey)
      try saveDownload(data, to: output)
    }
  }

  struct TaskFiles: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "task-files",
      abstract: "[space key] Download an archive of a conference's detection reference files.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Conference key.") var conferenceKey: String
    @Option(name: [.customShort("o"), .long], help: "Output file path.") var output: String
    func run() async throws {
      try saveDownload(
        try await global.makeClient().deepFakeTaskFiles(conferenceKey: conferenceKey), to: output)
    }
  }
}

/// `ktalk api-keys …` — inspect API keys.
struct ApiKeys: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "api-keys",
    abstract: "Inspect API keys.",
    subcommands: [List.self, AccessInfo.self]
  )
}

extension ApiKeys {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list", abstract: "[space key] List registered applications (API keys).")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().applications()) }
  }

  struct AccessInfo: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "access-info", abstract: "[space key] Show the current key's access info.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      try printJSON(try await global.makeClient().applicationAccessInfo())
    }
  }
}
