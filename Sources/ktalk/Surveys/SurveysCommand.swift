import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk surveys …` — manage surveys.
struct Surveys: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "surveys",
    abstract: "Manage surveys.",
    subcommands: [List.self, Get.self, Create.self, Update.self, Publish.self, Unpublish.self]
  )
}

extension Surveys {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list", abstract: "List surveys.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().listSurveys()) }
  }

  struct Get: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "get", abstract: "Get a survey by id.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Survey id.") var id: String
    func run() async throws { try printJSON(try await global.makeClient().survey(id: id)) }
  }

  struct Create: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "create", abstract: "Create a survey from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON SurveyRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.SurveyRequest.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().createSurvey(request))
    }
  }

  struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "update", abstract: "Update a survey from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Survey id.") var id: String
    @Option(name: .long, help: "Path to a JSON SurveyRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.SurveyRequest.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().updateSurvey(id: id, request: request))
    }
  }

  struct Publish: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "publish", abstract: "Publish a survey.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Survey id.") var id: String
    func run() async throws { try printJSON(try await global.makeClient().publishSurvey(id: id)) }
  }

  struct Unpublish: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "unpublish", abstract: "Unpublish a survey.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Survey id.") var id: String
    func run() async throws {
      try printJSON(try await global.makeClient().unpublishSurvey(id: id))
    }
  }
}
