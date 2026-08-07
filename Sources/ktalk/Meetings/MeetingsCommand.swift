import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk meetings …` — manage calendar meetings.
struct Meetings: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "meetings",
    abstract: "Manage calendar meetings.",
    subcommands: [
      List.self, Create.self, Edit.self, Cancel.self, EditAttendees.self, Recurrence.self,
    ]
  )
}

extension Meetings {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list", abstract: "List meetings for a calendar from a start date.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Calendar owner email.") var email: String
    @Option(name: .long, help: "Start date (ISO 8601).") var start: String
    @Option(name: .long, help: "End date (ISO 8601).") var end: String?
    @Option(name: .long, help: "Maximum number of meetings.") var take: Int?
    func run() async throws {
      let client = try global.makeClient()
      let result = try await client.listMeetings(
        email: email,
        start: try parseISODate(start),
        end: try end.map(parseISODate),
        take: take)
      try printJSON(result)
    }
  }

  struct Create: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "create", abstract: "Create a meeting from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Calendar owner email.") var email: String
    @Option(name: .long, help: "Path to a JSON CreateMeeting file.") var fromJSON: String
    func run() async throws {
      let client = try global.makeClient()
      let event = try decodeJSON(KTalkClient.CreateMeeting.self, fromFile: fromJSON)
      try printJSON(try await client.createMeeting(email: email, event: event))
    }
  }

  struct Edit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "edit", abstract: "Edit a meeting from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Calendar owner email.") var email: String
    @Argument(help: "Event id.") var eventId: String
    @Option(name: .long, help: "Path to a JSON EditMeeting file.") var fromJSON: String
    func run() async throws {
      let client = try global.makeClient()
      let event = try decodeJSON(KTalkClient.EditMeeting.self, fromFile: fromJSON)
      try printJSON(try await client.editMeeting(email: email, eventId: eventId, event: event))
    }
  }

  struct Cancel: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "cancel", abstract: "Cancel (delete) a meeting.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Calendar owner email.") var email: String
    @Argument(help: "Event id.") var eventId: String
    @Option(name: .long, help: "Optional notification message.") var message: String?
    func run() async throws {
      let client = try global.makeClient()
      try await client.cancelMeeting(email: email, eventId: eventId, message: message)
      try printJSON(Ack(email: email, eventId: eventId, action: "cancel"))
    }
  }

  struct EditAttendees: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "edit-attendees", abstract: "Edit a meeting's attendees from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Calendar owner email.") var email: String
    @Argument(help: "Event id.") var eventId: String
    @Option(name: .long, help: "Path to a JSON EditAttendees file.") var fromJSON: String
    func run() async throws {
      let client = try global.makeClient()
      let attendees = try decodeJSON(KTalkClient.EditAttendees.self, fromFile: fromJSON)
      try printJSON(
        try await client.editAttendees(email: email, eventId: eventId, attendees: attendees))
    }
  }

  struct Recurrence: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "recurrence", abstract: "Get the recurring series a meeting belongs to.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Calendar owner email.") var email: String
    @Argument(help: "Event id.") var eventId: String
    func run() async throws {
      let client = try global.makeClient()
      try printJSON(try await client.recurrenceSeries(email: email, eventId: eventId))
    }
  }

  private struct Ack: Encodable {
    let email: String
    let eventId: String
    let action: String
  }
}
