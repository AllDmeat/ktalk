import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk webhooks …` — manage webhook subscriptions.
struct Webhooks: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "webhooks",
    abstract: "Manage webhook subscriptions.",
    subcommands: [List.self, Create.self, Activate.self, Delete.self]
  )
}

extension Webhooks {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list", abstract: "List active webhooks.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      try printJSON(try await global.makeClient().listWebhooks())
    }
  }

  struct Create: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "create", abstract: "Create a webhook from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON CreateWebhookRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.CreateWebhookRequest.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().createWebhook(request))
    }
  }

  struct Activate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "activate", abstract: "Activate a webhook from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Webhook key.") var webhookKey: String
    @Option(name: .long, help: "Path to a JSON ActivateWebhookRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.ActivateWebhookRequest.self, fromFile: fromJSON)
      try await global.makeClient().activateWebhook(webhookKey: webhookKey, request: request)
      try printJSON(["webhook": webhookKey, "action": "activate"])
    }
  }

  struct Delete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete", abstract: "Delete a webhook.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Webhook key.") var webhookKey: String
    func run() async throws {
      try await global.makeClient().deleteWebhook(webhookKey: webhookKey)
      try printJSON(["webhook": webhookKey, "action": "delete"])
    }
  }
}
