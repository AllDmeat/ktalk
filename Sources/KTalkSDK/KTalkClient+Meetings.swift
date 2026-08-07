import Foundation

extension KTalkClient {
  /// A calendar meeting.
  public typealias Meeting =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_EmailCalendarItem
  /// The result of listing meetings for a calendar.
  public typealias MeetingList =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_EmailCalendarResult
  /// Parameters for creating a meeting.
  public typealias CreateMeeting =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_CreateEmailCalendarEventModel
  /// Parameters for editing a meeting.
  public typealias EditMeeting =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_EditEmailCalendarEventModel
  /// Parameters for editing a meeting's attendees.
  public typealias EditAttendees =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_EditEmailCalendarAttendeeModel

  /// Lists meetings for a calendar from `start` onward.
  public func listMeetings(
    email: String, start: Date, end: Date? = nil, take: Int? = nil
  ) async throws(KTalkError) -> MeetingList {
    try await call {
      let output = try await client.emailCalendarGetAll(
        .init(
          path: .init(email: email),
          query: .init(start: start, end: end, take: take.map(Int32.init))))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "calendar", identifier: email)
      }
    }
  }

  /// Creates a meeting in a calendar.
  public func createMeeting(email: String, event: CreateMeeting) async throws(KTalkError) -> Meeting
  {
    try await call {
      let output = try await client.emailCalendarCreate(
        .init(path: .init(email: email), body: .json(event)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "calendar", identifier: email)
      }
    }
  }

  /// Edits an existing meeting.
  public func editMeeting(email: String, eventId: String, event: EditMeeting)
    async throws(KTalkError) -> Meeting
  {
    try await call {
      let output = try await client.emailCalendarEdit(
        .init(path: .init(email: email, eventId: eventId), body: .json(event)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "meeting", identifier: eventId)
      }
    }
  }

  /// Cancels (deletes) a meeting, optionally notifying attendees with a message.
  public func cancelMeeting(email: String, eventId: String, message: String? = nil)
    async throws(KTalkError)
  {
    try await call {
      let output = try await client.emailCalendarCancel(
        .init(path: .init(email: email, eventId: eventId), query: .init(message: message)))
      switch output {
      case .ok: return
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "meeting", identifier: eventId)
      }
    }
  }

  /// Edits a meeting's attendees.
  public func editAttendees(email: String, eventId: String, attendees: EditAttendees)
    async throws(KTalkError) -> Meeting
  {
    try await call {
      let output = try await client.emailCalendarEditAttendee(
        .init(path: .init(email: email, eventId: eventId), body: .json(attendees)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "meeting", identifier: eventId)
      }
    }
  }

  /// Fetches the recurring series a meeting belongs to.
  public func recurrenceSeries(email: String, eventId: String) async throws(KTalkError) -> Meeting {
    try await call {
      let output = try await client.emailCalendarGetRecurrenceEventById(
        .init(path: .init(email: email, eventId: eventId)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "meeting", identifier: eventId)
      }
    }
  }
}
