import ArgumentParser
import Foundation
import KTalkSDK

/// `ktalk calendar …` — the calendar of the key's user.
struct CalendarCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "calendar",
    abstract: "Manage your own calendar (the key's user).",
    subcommands: [
      List.self, Create.self, BusyStatuses.self, Bindings.self, Bind.self, Unbind.self, Get.self,
      Edit.self, Recurrence.self, Ics.self, Accept.self, Reject.self, Cancel.self,
      EditAttendees.self,
    ]
  )
}

extension CalendarCommand {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list", abstract: "[personal key] List your calendar events from a start date.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Start date (ISO 8601).") var start: String
    @Option(name: .long, help: "End date (ISO 8601).") var end: String?
    @Option(name: .long, help: "Maximum number of events.") var take: Int?
    @Option(name: .long, help: "Only events in this room.") var room: String?
    @Flag(name: .long, help: "Oldest first.") var ascending = false
    @Flag(name: .long, help: "Skip events organized from a federated space.")
    var excludeFederation = false
    func validate() throws {
      try checkRange(take, "--take", 1...1000)
    }

    func run() async throws {
      let client = try global.makeClient()
      try printJSON(
        try await client.calendarEvents(
          start: try parseISODate(start), end: try end.map(parseISODate), take: take,
          roomName: room, ascendingOrder: ascending ? true : nil,
          excludeWithFederationOrganizer: excludeFederation ? true : nil))
    }
  }

  struct Create: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "create", abstract: "[personal key] Create an event from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON CreateCalendarEvent file.") var fromJSON: String
    func run() async throws {
      let event = try decodeJSON(KTalkClient.CreateCalendarEvent.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().createCalendarEvent(event))
    }
  }

  struct BusyStatuses: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "busy-statuses",
      abstract: "[personal key] Get users' busy intervals from a JSON request file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON BusyStatusRequest file.") var fromJSON: String
    func run() async throws {
      let request = try decodeJSON(KTalkClient.BusyStatusRequest.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().busyStatuses(request))
    }
  }

  struct Bindings: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "bindings", abstract: "[personal key] List your bound external calendars.")
    @OptionGroup var global: GlobalOptions
    func run() async throws {
      try printJSON(try await global.makeClient().externalCalendarBindings())
    }
  }

  struct Bind: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "bind", abstract: "[personal key] Bind an external calendar from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Option(name: .long, help: "Path to a JSON ExternalCalendarBinding file.") var fromJSON: String
    func run() async throws {
      let binding = try decodeJSON(KTalkClient.ExternalCalendarBinding.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().bindExternalCalendar(binding))
    }
  }

  struct Unbind: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "unbind", abstract: "[personal key] Unbind an external calendar.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Binding id.") var id: String
    func run() async throws {
      try await global.makeClient().unbindExternalCalendar(bindingId: id)
      try printJSON(Ack(id: id, action: "unbind"))
    }
  }

  struct Get: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "get", abstract: "[personal key] Get an event by id.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Event id.") var id: String
    func run() async throws {
      try printJSON(try await global.makeClient().calendarEvent(id: id))
    }
  }

  struct Edit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "edit", abstract: "[personal key] Edit an event from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Event id.") var id: String
    @Option(name: .long, help: "Path to a JSON EditCalendarEvent file.") var fromJSON: String
    func run() async throws {
      let event = try decodeJSON(KTalkClient.EditCalendarEvent.self, fromFile: fromJSON)
      try printJSON(try await global.makeClient().editCalendarEvent(id: id, event: event))
    }
  }

  struct Recurrence: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "recurrence", abstract: "[personal key] Get the series an event belongs to.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Event id.") var id: String
    func run() async throws {
      try printJSON(try await global.makeClient().calendarEventRecurrence(id: id))
    }
  }

  struct Ics: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "ics", abstract: "[personal key] Download an event as an ICS file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Event id.") var id: String
    @Flag(name: .long, help: "The event comes from a bound external calendar.")
    var external = false
    @Option(name: [.customShort("o"), .long], help: "Output file path.") var output: String
    func run() async throws {
      let data = try await global.makeClient().calendarEventICS(
        id: id, isExternalCalendar: external ? true : nil)
      try saveDownload(data, to: output)
    }
  }

  struct Accept: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "accept", abstract: "[personal key] Accept an invitation.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Event id.") var id: String
    func run() async throws {
      try await global.makeClient().acceptCalendarEvent(id: id)
      try printJSON(Ack(id: id, action: "accept"))
    }
  }

  struct Reject: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "reject", abstract: "[personal key] Decline an invitation.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Event id.") var id: String
    @Flag(name: .long, help: "Notify the organizer.") var notify = false
    func run() async throws {
      try await global.makeClient().rejectCalendarEvent(
        id: id, withNotification: notify ? true : nil)
      try printJSON(Ack(id: id, action: "reject"))
    }
  }

  struct Cancel: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "cancel", abstract: "[personal key] Cancel an event you organize.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Event id.") var id: String
    @Option(name: .long, help: "Message to attendees.") var message: String?
    func run() async throws {
      try await global.makeClient().cancelCalendarEvent(id: id, message: message)
      try printJSON(Ack(id: id, action: "cancel"))
    }
  }

  struct EditAttendees: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "edit-attendees",
      abstract: "[personal key] Edit an event's attendees from a JSON file.")
    @OptionGroup var global: GlobalOptions
    @Argument(help: "Event id.") var id: String
    @Option(name: .long, help: "Path to a JSON EditCalendarEventAttendees file.") var fromJSON:
      String
    func run() async throws {
      let attendees = try decodeJSON(
        KTalkClient.EditCalendarEventAttendees.self, fromFile: fromJSON)
      try printJSON(
        try await global.makeClient().editCalendarEventAttendees(id: id, attendees: attendees))
    }
  }

  private struct Ack: Encodable {
    let id: String
    let action: String
  }
}
