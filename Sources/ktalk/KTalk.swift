import ArgumentParser
import KTalkSDK

/// The root command for the `ktalk` command-line tool.
///
/// Subcommands (one group per API tag) are added in later changes. Each command builds a
/// ``KTalkClient`` from the `KTALK_BASE_URL` / `KTALK_TOKEN` environment variables (or the
/// `--base-url` / `--token` flags) and prints its result as JSON.
@main
struct KTalk: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "ktalk",
    abstract: "Command-line client for the Kontur.Talk API.",
    version: KTalkSDK.version,
    subcommands: []
  )
}
