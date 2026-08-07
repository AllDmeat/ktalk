import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk users …` — search and manage users.
struct Users: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "users",
    abstract: "Search and manage users.",
    subcommands: [
      Search.self, Scan.self, Get.self, CreateOrUpdate.self, Delete.self, RevokeSessions.self,
      Roles.self, ChangeRoles.self, SetPermissions.self,
    ]
  )
}

extension Users {
  struct Search: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "search", abstract: "Search users.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Free-text query.") var query: String?
    @Option(name: .long, help: "Filter by email (repeatable).") var email: [String] = []
    @Option(name: .long, help: "Filter by role.") var role: String?
    @Option(name: .long, help: "Skip N.") var skip: Int?
    @Option(name: .long, help: "Take N.") var top: Int?
    @Flag(name: .long, help: "Include disabled users.") var includeDisabled = false
    @Flag(name: .long, help: "Include guests.") var includeGuests = false
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(
        try await client.searchUsers(
          query: query, emails: email.isEmpty ? nil : email, role: role, skip: skip,
          top: top, includeDisabled: includeDisabled ? true : nil,
          includeGuests: includeGuests ? true : nil))
    }
  }

  struct Scan: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "scan", abstract: "Scan all users.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Offset cursor.") var offset: String?
    @Option(name: .long, help: "Take N.") var top: Int?
    @Option(name: .long, help: "Filter by role.") var role: String?
    @Flag(name: .long, help: "Include disabled users.") var includeDisabled = false
    @Flag(name: .long, help: "Include guests.") var includeGuests = false
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(
        try await client.scanUsers(
          offset: offset, top: top, includeDisabled: includeDisabled ? true : nil,
          includeGuests: includeGuests ? true : nil, role: role))
    }
  }

  struct Get: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "get", abstract: "Get a user by key.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.user(key: key))
    }
  }

  struct CreateOrUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "create-or-update",
      abstract: "Create, update, or restore users from a JSON array file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON array of user params.") var fromJSON: String
    func run() async throws {
      let client = try global.makeClient()
      let users = try decodeJSON([KTalkClient.UserParams].self, fromFile: fromJSON)
      try printJSON(try await client.createOrUpdateUsers(users))
    }
  }

  struct Delete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete", abstract: "Delete a user.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    func run() async throws {
      let client = try global.makeClient()
      try await client.deleteUser(key: key)
      try printJSON(Ack(userKey: key, action: "delete"))
    }
  }

  struct RevokeSessions: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "revoke-sessions", abstract: "Revoke all of a user's sessions.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    func run() async throws {
      let client = try global.makeClient()
      try await client.revokeSessions(userKey: key)
      try printJSON(Ack(userKey: key, action: "revoke-sessions"))
    }
  }

  struct Roles: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "roles", abstract: "Get a user's roles.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.userRoles(userKey: key))
    }
  }

  struct ChangeRoles: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "change-roles", abstract: "Change a user's roles from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    @Option(name: .long, help: "Path to a JSON ChangeRolesRequest file.") var fromJSON: String
    func run() async throws {
      let client = try global.makeClient()
      let request = try decodeJSON(KTalkClient.ChangeRolesRequest.self, fromFile: fromJSON)
      try printJSON(try await client.changeRoles(userKey: key, request: request))
    }
  }

  struct SetPermissions: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "set-permissions",
      abstract: "Set a user's permissions (block/restore) from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    @Option(name: .long, help: "Path to a JSON UserPermissions file.") var fromJSON: String
    func run() async throws {
      let client = try global.makeClient()
      let permissions = try decodeJSON(KTalkClient.UserPermissions.self, fromFile: fromJSON)
      try printJSON(try await client.setPermissions(userKey: key, permissions: permissions))
    }
  }

  private struct Ack: Encodable {
    let userKey: String
    let action: String
  }
}
