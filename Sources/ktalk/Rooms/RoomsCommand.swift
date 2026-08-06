import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk rooms …` — inspect and manage rooms.
struct Rooms: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "rooms",
    abstract: "Inspect and manage rooms.",
    subcommands: [
      Get.self, Update.self, Lock.self, EndConference.self, AddModerator.self,
      RemoveModerator.self,
    ]
  )
}

extension Rooms {
  struct Get: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "get", abstract: "Get a room by name.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.room(name: name))
    }
  }

  struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "update", abstract: "Create or update a room from a JSON params file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Option(name: .long, help: "Path to a JSON file with the room params.") var fromJSON: String
    func run() async throws {
      let client = try global.makeClient()
      let params = try decodeJSON(KTalkClient.RoomParams.self, fromFile: fromJSON)
      try printJSON(try await client.updateRoom(name: name, params: params))
    }
  }

  struct Lock: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "lock",
      abstract: "Set or clear a room's PIN and masking from a JSON request file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Option(name: .long, help: "Path to a JSON LockRoomRequest file.") var fromJSON: String
    func run() async throws {
      let client = try global.makeClient()
      let request = try decodeJSON(KTalkClient.LockRoomRequest.self, fromFile: fromJSON)
      try await client.setRoomLock(roomName: name, request: request)
      try printJSON(Ack(room: name, action: "lock"))
    }
  }

  struct EndConference: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "end-conference", abstract: "Forcibly end a room's conference.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    func run() async throws {
      let client = try global.makeClient()
      try await client.endConference(roomName: name)
      try printJSON(Ack(room: name, action: "end-conference"))
    }
  }

  struct AddModerator: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "add-moderator", abstract: "Add a moderator to a room.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Argument(help: "User reference (key or email).") var userRef: String
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.addModerator(roomName: name, userRef: userRef))
    }
  }

  struct RemoveModerator: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "remove-moderator", abstract: "Remove a moderator from a room.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Argument(help: "User reference (key or email).") var userRef: String
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.removeModerator(roomName: name, userRef: userRef))
    }
  }

  private struct Ack: Encodable {
    let room: String
    let action: String
  }
}
