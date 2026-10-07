import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk kiosks …` — inspect and manage kiosks.
struct Kiosks: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "kiosks",
    abstract: "Inspect and manage kiosks.",
    subcommands: [
      List.self, Get.self, Create.self, Update.self, Delete.self, Search.self, Gadgets.self,
      News.self, Screensavers.self, Wallpapers.self, Count.self, Versions.self, Block.self,
      Unblock.self, EquipmentCheck.self, CurrentEvent.self, Groups.self, CreateGroup.self,
      UpdateGroup.self, DeleteGroup.self, Move.self, MassUpdate.self, AddNotificationUnit.self,
      RemoveNotificationUnit.self, UploadScreensavers.self, DeleteScreensaver.self,
      UploadWallpapers.self, DeleteWallpaper.self, SetDefaultWallpapers.self,
    ]
  )
}

extension Kiosks {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list", abstract: "[space key] List kiosks.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().listKiosks()) }
  }

  struct Get: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "get", abstract: "[space key] Get a kiosk by id.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Kiosk id.") var id: String
    func run() async throws { try printJSON(try await global.makeClient().kiosk(id: id)) }
  }

  struct Create: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "create", abstract: "Create a kiosk from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON KioskCreateParams file.") var fromJSON: String
    func run() async throws {
      let params = try decodeJSON(KTalkClient.KioskCreateParams.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().createKiosk(params))
    }
  }

  struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "update", abstract: "Update a kiosk from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Kiosk id.") var id: String
    @Option(name: .long, help: "Path to a JSON KioskUpdateParams file.") var fromJSON: String
    func run() async throws {
      let params = try decodeJSON(KTalkClient.KioskUpdateParams.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().updateKiosk(id: id, params: params))
    }
  }

  struct Delete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete", abstract: "Delete a kiosk.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Kiosk id.") var id: String
    func run() async throws {
      try await global.makeClient().deleteKiosk(id: id)
      try printJSON(["kiosk": id, "action": "delete"])
    }
  }

  struct Search: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "search", abstract: "[space key] Search kiosks.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().searchKiosks()) }
  }

  struct Gadgets: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "gadgets", abstract: "[space key] List kiosk gadgets.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().kioskGadgets()) }
  }

  struct News: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "news", abstract: "[space key] Fetch kiosk news / support requests.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().kioskNews()) }
  }

  struct Screensavers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "screensavers", abstract: "[space key] List kiosk screensavers.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().kioskScreensavers()) }
  }

  struct Wallpapers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "wallpapers", abstract: "[space key] List kiosk wallpapers.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().kioskWallpapers()) }
  }

  struct Count: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "count", abstract: "[space key] Count the kiosks that match the filters.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Free-text search.") var search: String?
    @Option(name: .long, help: "Status filter as free text.") var status: String?
    @Option(name: .long, help: "Status value. Repeat for several.")
    var statusValue: [KTalkClient.KioskStatus] = []
    @Option(name: .long, help: "App version.") var version: String?
    @Option(name: .long, help: "Skip N kiosks.") var offset: Int?
    @Option(name: .long, help: "Page size.") var pageSize: Int?
    @Option(name: .long, help: "Kiosk group key.") var group: String?
    func validate() throws {
      try checkRange(offset, "--offset", 0...int32Max)
      try checkRange(pageSize, "--page-size", 1...int32Max)
    }

    func run() async throws {
      let count = try await global.makeClient().kioskCount(
        complexSearch: search, status: status,
        statusValues: statusValue.isEmpty ? nil : statusValue,
        version: version, offset: offset, pageSize: pageSize, groupKey: group)
      try printJSON(["count": count])
    }
  }

  struct Versions: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "versions",
      abstract: "[space key] List the app versions installed on the kiosks.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      try printJSON(try await global.makeClient().kioskVersions())
    }
  }

  struct Block: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "block", abstract: "Block a kiosk.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Kiosk id.") var id: String
    func run() async throws {
      try await global.makeClient().blockKiosk(id: id)
      try printJSON(["kiosk": id, "action": "block"])
    }
  }

  struct Unblock: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "unblock", abstract: "Unblock a kiosk.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Kiosk id.") var id: String
    func run() async throws {
      try await global.makeClient().unblockKiosk(id: id)
      try printJSON(["kiosk": id, "action": "unblock"])
    }
  }

  struct EquipmentCheck: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "equipment-check", abstract: "Start an equipment check on a kiosk.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Kiosk id.") var id: String
    func run() async throws {
      try await global.makeClient().checkKioskEquipment(id: id)
      try printJSON(["kiosk": id, "action": "equipment-check"])
    }
  }

  struct CurrentEvent: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "current-event",
      abstract: "[space key] Get the event running in a kiosk's calendar now.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Kiosk id.") var id: String
    func run() async throws {
      try printJSON(try await global.makeClient().kioskCurrentEvent(id: id))
    }
  }

  struct Groups: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "groups", abstract: "[space key] Get the tree of kiosk groups.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      try printJSON(try await global.makeClient().kioskGroups())
    }
  }

  struct CreateGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "create-group", abstract: "Create a kiosk group from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON KioskCreateGroupRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.KioskCreateGroupRequest.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().createKioskGroup(request))
    }
  }

  struct UpdateGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "update-group", abstract: "Update a kiosk group from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Group key.") var key: String
    @Option(name: .long, help: "Path to a JSON KioskUpdateGroupRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.KioskUpdateGroupRequest.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().updateKioskGroup(key: key, request: request))
    }
  }

  struct DeleteGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete-group", abstract: "Delete a kiosk group.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Group key.") var key: String
    func run() async throws {
      try await global.makeClient().deleteKioskGroup(key: key)
      try printJSON(["group": key, "action": "delete"])
    }
  }

  struct Move: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "move", abstract: "Move kiosks into a group from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON KioskMoveRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.KioskMoveRequest.self, fromFile: fromJSON)
      try await global.makeClient().moveKiosks(request)
      try printJSON(["action": "move"])
    }
  }

  struct MassUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "mass-update",
      abstract: "Apply settings to many kiosks at once from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON KioskMassUpdateRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.KioskMassUpdateRequest.self, fromFile: fromJSON)
      try await global.makeClient().massUpdateKiosks(request)
      try printJSON(["action": "mass-update"])
    }
  }

  struct AddNotificationUnit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "add-notification-unit",
      abstract: "Subscribe a user to status notifications of every kiosk and gadget.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON KioskNotificationUnit file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.KioskNotificationUnit.self, fromFile: fromJSON)
      try await global.makeClient().addKioskNotificationUnit(request)
      try printJSON(["action": "add-notification-unit"])
    }
  }

  struct RemoveNotificationUnit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "remove-notification-unit",
      abstract: "Remove a user's status-notification subscription from every kiosk.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON KioskNotificationUnit file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.KioskNotificationUnit.self, fromFile: fromJSON)
      try await global.makeClient().removeKioskNotificationUnit(request)
      try printJSON(["action": "remove-notification-unit"])
    }
  }

  struct UploadScreensavers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "upload-screensavers", abstract: "Upload kiosk screensavers.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Image or video files to upload.") var files: [String]
    @Option(name: .long, help: "Media type to send, e.g. image/png (default: from the extension).")
    var contentType: String?
    func run() async throws {
      let uploads = try files.map { try uploadFile(atPath: $0, contentType: contentType) }
      try printJSON(try await global.makeClient().uploadKioskScreensavers(uploads))
    }
  }

  struct DeleteScreensaver: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete-screensaver", abstract: "Delete a kiosk screensaver.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Screensaver key.") var key: String
    func run() async throws {
      try printJSON(try await global.makeClient().deleteKioskScreensaver(key: key))
    }
  }

  struct UploadWallpapers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "upload-wallpapers", abstract: "Upload kiosk wallpapers.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Image files to upload.") var files: [String]
    @Option(name: .long, help: "Media type to send, e.g. image/png (default: from the extension).")
    var contentType: String?
    func run() async throws {
      let uploads = try files.map { try uploadFile(atPath: $0, contentType: contentType) }
      try printJSON(try await global.makeClient().uploadKioskWallpapers(uploads))
    }
  }

  struct DeleteWallpaper: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete-wallpaper", abstract: "Delete a kiosk wallpaper.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Wallpaper key.") var key: String
    func run() async throws {
      try printJSON(try await global.makeClient().deleteKioskWallpaper(key: key))
    }
  }

  struct SetDefaultWallpapers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "set-default-wallpapers",
      abstract: "Choose the wallpapers kiosks show, from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON KioskWallpaperSettings file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.KioskWallpaperSettings.self, fromFile: fromJSON)
      try await global.makeClient().setDefaultKioskWallpapers(request)
      try printJSON(["action": "set-default-wallpapers"])
    }
  }
}
