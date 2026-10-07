import ArgumentParser
import KTalkSDK

/// The root command for the `ktalk` command-line tool.
///
/// One subcommand group per API tag. Each command builds a ``KTalkClient`` from the
/// `KTALK_BASE_URL` / `KTALK_TOKEN` environment variables (or the `--base-url` / `--token`
/// flags) and prints its result as JSON.
@main
struct KTalk: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "ktalk",
    abstract: "Command-line client for the Kontur.Talk API.",
    discussion: """
      Kontur.Talk issues two kinds of keys. A space key comes from the admin panel → API keys \
      and acts for the whole space. A personal key comes from your profile → Settings → API \
      keys and acts with your own rights.

      A command's description starts with the key it takes:

      [personal key] works with a personal key.

      [space key] needs a space key: a personal key gets 403.

      Commands without a tag change data and have not been checked with a personal key.
      """,
    version: KTalkSDK.version,
    subcommands: [
      Recordings.self, Rooms.self, Meetings.self, Reports.self, Users.self, RolesCommand.self,
      Webhooks.self, Stats.self, Surveys.self, Kiosks.self, CalendarServers.self, DeepFake.self,
      ApiKeys.self, TelemetryCommand.self,
    ]
  )
}
