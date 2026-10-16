import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk whiteboards …` — read whiteboards.
struct Whiteboards: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "whiteboards",
    abstract: "Read whiteboards.",
    subcommands: [State.self]
  )
}

extension Whiteboards {
  struct State: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "state",
      abstract: "[personal key] Get a whiteboard's metadata and elements.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Whiteboard key.") var key: String
    func run() async throws {
      try printJSON(try await global.makeClient().whiteboardState(key: key))
    }
  }
}
