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
      RemoveModerator.self, SetAnonymousAccess.self, NotifyCall.self, CancelCall.self,
      Recordings.self, UploadFile.self, SetSimultaneousTranslation.self, GenerateSip.self,
      DisableSip.self, AddChatUser.self, RemoveChatUser.self, StartConference.self,
      KickUser.self, ChangeUserName.self, OnlineUsers.self, ConferenceLimits.self,
      CreateChat.self,
    ]
  )
}

extension Rooms {
  struct Get: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "get", abstract: "[personal key] Get a room by name.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.room(name: name))
    }
  }

  struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "update",
      abstract: "[personal key] Create or update a room from a JSON params file.")
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
      abstract: "[personal key] Set or clear a room's PIN and masking from a JSON request file.")
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
      commandName: "end-conference", abstract: "[personal key] Forcibly end a room's conference.")
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
      commandName: "add-moderator",
      abstract: "[personal key] Add a moderator to a room.")
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
      commandName: "remove-moderator",
      abstract: "[personal key] Remove a moderator from a room.")
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

  struct SetAnonymousAccess: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "set-anonymous-access",
      abstract:
        "[personal key] Change whether external participants can join a room, from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Option(name: .long, help: "Path to a JSON AnonymousAccessRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.AnonymousAccessRequest.self, fromFile: fromJSON)
      try printJSON(
        try await global.makeClient().setAnonymousAccess(roomName: name, request: request))
    }
  }

  struct NotifyCall: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "notify-call",
      abstract: "[space key] Notify users of a call from a room, from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Option(name: .long, help: "Path to a JSON NotifyCallParams file.") var fromJSON: String
    func run() async throws {
      let params = try decodeJSON(KTalkClient.NotifyCallParams.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().notifyCall(roomName: name, params: params))
    }
  }

  struct CancelCall: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "cancel-call",
      abstract: "[space key] Cancel a call from a room, from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Option(name: .long, help: "Path to a JSON CancelCallParams file.") var fromJSON: String
    func run() async throws {
      let params = try decodeJSON(KTalkClient.CancelCallParams.self, fromFile: fromJSON)
      try await global.makeClient().cancelCall(roomName: name, params: params)
      try printJSON(["room": name, "action": "cancel-call"])
    }
  }

  struct Recordings: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "recordings", abstract: "[personal key] List a room's recordings (one page).")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Option(name: .long, help: "Page size.") var top: Int?
    @Option(name: .long, help: "Token of the page to fetch, from a previous page.")
    var pageToken: String?
    func validate() throws {
      try checkRange(top, "--top", 1...int32Max)
    }

    func run() async throws {
      try printJSON(
        try await global.makeClient().roomRecordings(name: name, top: top, pageToken: pageToken))
    }
  }

  struct UploadFile: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "upload-file", abstract: "[personal key] Upload a file (up to 50 MB) to a room.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Argument(help: "File to upload.") var file: String
    @Option(name: .long, help: "Media type to send (default: from the extension).")
    var contentType: String?
    func run() async throws {
      let upload = try uploadFile(atPath: file, contentType: contentType)
      try printJSON(try await global.makeClient().uploadRoomFile(roomName: name, file: upload))
    }
  }

  struct SetSimultaneousTranslation: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "set-simultaneous-translation",
      abstract:
        "[personal key] Change a room's simultaneous translation from a JSON file."
    )
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Option(name: .long, help: "Path to a JSON SimultaneousTranslationRequest file.")
    var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(
        KTalkClient.SimultaneousTranslationRequest.self, fromFile: fromJSON)
      try printJSON(
        try await global.makeClient().setSimultaneousTranslation(roomName: name, request: request))
    }
  }

  struct GenerateSip: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "generate-sip", abstract: "[personal key] Give a room a SIP number.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    func run() async throws {
      try printJSON(try await global.makeClient().generateSipNumber(roomName: name))
    }
  }

  struct DisableSip: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "disable-sip", abstract: "[personal key] Take a room's SIP number away.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    func run() async throws {
      try await global.makeClient().disableSipNumber(roomName: name)
      try printJSON(["room": name, "action": "disable-sip"])
    }
  }

  struct AddChatUser: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "add-chat-user",
      abstract: "[personal key] Allow a user to write in a room's chat channel.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Argument(help: "User key or anonymous participant id.") var userRef: String
    func run() async throws {
      try printJSON(
        try await global.makeClient().addChatChannelUser(roomName: name, userRef: userRef))
    }
  }

  struct RemoveChatUser: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "remove-chat-user",
      abstract: "[personal key] Stop a user writing in a room's chat channel.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Argument(help: "User key or anonymous participant id.") var userRef: String
    func run() async throws {
      try printJSON(
        try await global.makeClient().removeChatChannelUser(roomName: name, userRef: userRef))
    }
  }

  struct StartConference: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "start-conference",
      abstract: "[personal key] Start a room's conference from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Option(name: .long, help: "Path to a JSON StartConferenceProperties file.") var fromJSON:
      String
    func run() async throws {
      let properties = try decodeJSON(
        KTalkClient.StartConferenceProperties.self, fromFile: fromJSON)
      try printJSON(
        try await global.makeClient().startConference(roomName: name, properties: properties))
    }
  }

  struct KickUser: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "kick-user",
      abstract: "[personal key] Remove a participant from a room's conference, from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Option(name: .long, help: "Path to a JSON KickUserRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.KickUserRequest.self, fromFile: fromJSON)
      try await global.makeClient().kickUser(roomName: name, request: request)
      try printJSON(["room": name, "action": "kick-user"])
    }
  }

  struct ChangeUserName: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "change-user-name",
      abstract: "[personal key] Rename an anonymous participant, from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Option(name: .long, help: "Path to a JSON ChangeUserNameRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.ChangeUserNameRequest.self, fromFile: fromJSON)
      try await global.makeClient().changeParticipantName(roomName: name, request: request)
      try printJSON(["room": name, "action": "change-user-name"])
    }
  }

  struct OnlineUsers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "online-users", abstract: "[personal key] List who is in a room right now.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    func run() async throws {
      try printJSON(try await global.makeClient().onlineUsers(roomName: name))
    }
  }

  struct ConferenceLimits: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "conference-limits",
      abstract: "[personal key] Show how long a room's conference may still run.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Room name.") var name: String
    @Flag(name: .long, help: "Report the limits as if the conference were starting now.")
    var forceStart = false
    func run() async throws {
      try printJSON(
        try await global.makeClient().conferenceLimits(
          roomName: name, forceStart: forceStart ? true : nil))
    }
  }

  struct CreateChat: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "create-chat", abstract: "[personal key] Create a chat room from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON CreateMessengerRoomRequest file.")
    var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.CreateMessengerRoomRequest.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().createMessengerRoom(request))
    }
  }
}
