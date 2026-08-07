import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk roles …` — inspect and manage roles.
struct RolesCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "roles",
    abstract: "Inspect and manage roles.",
    subcommands: [
      List.self, Get.self, Create.self, Update.self, Delete.self, Permissions.self,
      Defaults.self,
    ]
  )
}

extension RolesCommand {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List roles.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      try printJSON(try await global.makeClient().listRoles())
    }
  }

  struct Get: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "get", abstract: "Get a role by id.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Role id.") var id: String
    func run() async throws {
      try printJSON(try await global.makeClient().role(id: id))
    }
  }

  struct Create: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "create", abstract: "Create a role from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON RoleCreateRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.RoleCreateRequest.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().createRole(request))
    }
  }

  struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "update", abstract: "Update a role from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Role id.") var id: String
    @Option(name: .long, help: "Path to a JSON RoleUpdateRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.RoleUpdateRequest.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().updateRole(id: id, request: request))
    }
  }

  struct Delete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete", abstract: "Delete a role.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Role id.") var id: String
    func run() async throws {
      try await global.makeClient().deleteRole(id: id)
      try printJSON(["role": id, "action": "delete"])
    }
  }

  struct Permissions: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "permissions", abstract: "List available permissions.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      try printJSON(try await global.makeClient().permissions())
    }
  }

  struct Defaults: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "defaults", abstract: "List default roles.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      try printJSON(try await global.makeClient().defaultRoles())
    }
  }
}
