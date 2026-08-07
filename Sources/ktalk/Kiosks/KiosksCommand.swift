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
      News.self, Screensavers.self, Wallpapers.self,
    ]
  )
}

extension Kiosks {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List kiosks.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().listKiosks()) }
  }

  struct Get: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "get", abstract: "Get a kiosk by id.")
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
      commandName: "search", abstract: "Search kiosks.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().searchKiosks()) }
  }

  struct Gadgets: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "gadgets", abstract: "List kiosk gadgets.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().kioskGadgets()) }
  }

  struct News: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "news", abstract: "Fetch kiosk news / support requests.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().kioskNews()) }
  }

  struct Screensavers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "screensavers", abstract: "List kiosk screensavers.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().kioskScreensavers()) }
  }

  struct Wallpapers: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "wallpapers", abstract: "List kiosk wallpapers.")
    @OptionGroup var global: GlobalOptions
    func run() async throws { try printJSON(try await global.makeClient().kioskWallpapers()) }
  }
}
