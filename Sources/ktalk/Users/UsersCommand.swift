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
      Roles.self, ChangeRoles.self, SetPermissions.self, UploadAvatar.self, DeleteAvatar.self,
      SyncAvatar.self, Profile.self, UpdateProfile.self, DeleteSelf.self,
      UnlockSelfDeleted.self, Logout.self, UploadOwnAvatar.self, DeleteOwnAvatar.self,
      AddRole.self, RemoveRole.self,
    ]
  )
}

extension Users {
  struct Search: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "search", abstract: "[personal key] Search users.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Free-text query.") var query: String?
    @Option(name: .long, help: "Filter by email (repeatable).") var email: [String] = []
    @Option(name: .long, help: "Filter by role.") var role: String?
    @Option(name: .long, help: "Skip N.") var skip: Int?
    @Option(name: .long, help: "Take N.") var top: Int?
    @Flag(name: .long, help: "Include disabled users.") var includeDisabled = false
    @Flag(name: .long, help: "Include guests.") var includeGuests = false
    func validate() throws {
      try checkRange(skip, "--skip", 0...int32Max)
      try checkRange(top, "--top", 1...1000)
    }

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
      commandName: "scan", abstract: "[personal key] Scan all users.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Offset cursor.") var offset: String?
    @Option(name: .long, help: "Take N.") var top: Int?
    @Option(name: .long, help: "Filter by role.") var role: String?
    @Flag(name: .long, help: "Include disabled users.") var includeDisabled = false
    @Flag(name: .long, help: "Include guests.") var includeGuests = false
    func validate() throws {
      try checkRange(top, "--top", 1...1000)
    }

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
      commandName: "get", abstract: "[personal key] Get a user by key.")
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
      abstract: "[personal key] Create, update, or restore users from a JSON array file.")
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
      commandName: "delete", abstract: "[personal key] Delete a user.")
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
      commandName: "revoke-sessions", abstract: "[space key] Revoke all of a user's sessions.")
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
      commandName: "roles", abstract: "[personal key] Get a user's roles.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.userRoles(userKey: key))
    }
  }

  struct ChangeRoles: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "change-roles",
      abstract: "[personal key] Change a user's roles from a JSON file.")
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
      abstract:
        "[personal key] Set a user's permissions (block/restore) from a JSON file."
    )
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

  struct UploadAvatar: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "upload-avatar", abstract: "[personal key] Upload a user's avatar.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    @Argument(help: "Image file.") var file: String
    @Option(name: .long, help: "Media type to send, e.g. image/png (default: from the extension).")
    var contentType: String?
    func run() async throws {
      let upload = try uploadFile(atPath: file, contentType: contentType)
      try printJSON(try await global.makeClient().uploadAvatar(userKey: key, file: upload))
    }
  }

  struct DeleteAvatar: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete-avatar", abstract: "[personal key] Delete a user's avatar.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    func run() async throws {
      try await global.makeClient().deleteAvatar(userKey: key)
      try printJSON(["user": key, "action": "delete-avatar"])
    }
  }

  struct SyncAvatar: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "sync-avatar",
      abstract: "[personal key] Re-sync a user's avatar from the identity provider.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    func run() async throws {
      try await global.makeClient().syncAvatar(userKey: key)
      try printJSON(["user": key, "action": "sync-avatar"])
    }
  }

  struct Profile: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "profile", abstract: "[personal key] Get your own profile.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      try printJSON(try await global.makeClient().profile())
    }
  }

  struct UpdateProfile: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "update-profile",
      abstract: "[personal key] Update your own profile from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON ProfileParams file.") var fromJSON: String
    func run() async throws {
      let params = try decodeJSON(KTalkClient.ProfileParams.self, fromFile: fromJSON)
      try await global.makeClient().updateProfile(params)
      try printJSON(["action": "update-profile"])
    }
  }

  struct DeleteSelf: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete-self",
      abstract: "[personal key] Delete your own user, from a JSON options file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON DeleteSelfParams file.") var fromJSON: String
    func run() async throws {
      let params = try decodeJSON(KTalkClient.DeleteSelfParams.self, fromFile: fromJSON)
      try await global.makeClient().deleteSelf(params)
      try printJSON(["action": "delete-self"])
    }
  }

  struct UnlockSelfDeleted: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "unlock-self-deleted",
      abstract: "[personal key] Restore a user who deleted themselves.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    func run() async throws {
      try await global.makeClient().unlockSelfDeleted(userKey: key)
      try printJSON(["user": key, "action": "unlock-self-deleted"])
    }
  }

  struct Logout: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "logout",
      abstract: "[personal key] End your own sessions, from a JSON options file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON DeleteSelfParams file.") var fromJSON: String
    func run() async throws {
      let params = try decodeJSON(KTalkClient.DeleteSelfParams.self, fromFile: fromJSON)
      try await global.makeClient().logOut(params)
      try printJSON(["action": "logout"])
    }
  }

  struct UploadOwnAvatar: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "upload-own-avatar", abstract: "[personal key] Upload your own avatar.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Image file.") var file: String
    @Option(name: .long, help: "Media type to send, e.g. image/png (default: from the extension).")
    var contentType: String?
    func run() async throws {
      let upload = try uploadFile(atPath: file, contentType: contentType)
      try printJSON(try await global.makeClient().uploadOwnAvatar(file: upload))
    }
  }

  struct DeleteOwnAvatar: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete-own-avatar", abstract: "[personal key] Delete your own avatar.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      try await global.makeClient().deleteOwnAvatar()
      try printJSON(["action": "delete-own-avatar"])
    }
  }

  struct AddRole: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "add-role", abstract: "[personal key] Give a user a role.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    @Argument(help: "Role id.") var role: String
    func run() async throws {
      try await global.makeClient().addRole(userKey: key, role: role)
      try printJSON(["user": key, "role": role, "action": "add-role"])
    }
  }

  struct RemoveRole: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "remove-role",
      abstract: "[personal key] Take a role from a user.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "User key.") var key: String
    @Argument(help: "Role id.") var role: String
    func run() async throws {
      try await global.makeClient().removeRole(userKey: key, role: role)
      try printJSON(["user": key, "role": role, "action": "remove-role"])
    }
  }
}
