import Foundation

/// The calendar of the key's user (`/api/Calendar`), from the personal access token spec.
///
/// Unlike ``listMeetings(email:start:end:take:)``, which reads any mailbox with a space key,
/// these act on the calendar of whoever issued the key.
extension KTalkClient {
  /// An event in the user's calendar.
  public typealias CalendarEvent =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_TalkCalendarItem
  /// A page of the user's calendar events.
  public typealias CalendarEventList =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_TalkCalendarResult
  /// Parameters for creating a calendar event.
  public typealias CreateCalendarEvent =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_TalkCreateCalendarEventModel
  /// Parameters for editing a calendar event.
  public typealias EditCalendarEvent =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_TalkEditCalendarEventModel
  /// Parameters for editing a calendar event's attendees.
  public typealias EditCalendarEventAttendees =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_AttendeeEditModel
  /// A request for users' busy intervals.
  public typealias BusyStatusRequest =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_GetUsersBusyStatusRequest
  /// A user's busy interval.
  public typealias BusyStatus =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_UserBusyStatus
  /// An external calendar bound to the user's calendar by its ICS link.
  public typealias ExternalCalendarBinding =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Calendar_BindExternalCalendarModel

  /// Lists the user's calendar events from `start` onward.
  public func calendarEvents(
    start: Date, end: Date? = nil, take: Int? = nil, roomName: String? = nil,
    ascendingOrder: Bool? = nil, excludeWithFederationOrganizer: Bool? = nil
  ) async throws(KTalkError) -> CalendarEventList {
    try await call {
      switch try await client.calendarGet(
        .init(
          query: .init(
            start: start, end: end, take: take.map { Int32(clamping: $0) }, roomName: roomName,
            ascendingOrder: ascendingOrder,
            excludeWithFederationOrganizer: excludeWithFederationOrganizer)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Creates an event in the user's calendar.
  public func createCalendarEvent(_ event: CreateCalendarEvent) async throws(KTalkError)
    -> CalendarEvent
  {
    try await call {
      switch try await client.calendarCreateCalendarEvent(.init(body: .json(event))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Fetches users' busy intervals.
  public func busyStatuses(_ request: BusyStatusRequest) async throws(KTalkError) -> [BusyStatus] {
    try await call {
      switch try await client.calendarGetUsersBusyStatuses(.init(body: .json(request))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Lists the external calendars bound to the user's calendar.
  public func externalCalendarBindings() async throws(KTalkError) -> [ExternalCalendarBinding] {
    try await call {
      switch try await client.calendarGetExternalCalendarsBindings() {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Binds an external calendar to the user's calendar.
  public func bindExternalCalendar(_ binding: ExternalCalendarBinding) async throws(KTalkError)
    -> ExternalCalendarBinding
  {
    try await call {
      switch try await client.calendarBindExternalCalendar(.init(body: .json(binding))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Unbinds an external calendar.
  public func unbindExternalCalendar(bindingId: String) async throws(KTalkError) {
    try await call {
      switch try await client.calendarUnbindExternalCalendar(
        .init(path: .init(bindingId: bindingId)))
      {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "calendar binding", identifier: bindingId)
      }
    }
  }

  /// Fetches an event from the user's calendar.
  public func calendarEvent(id: String) async throws(KTalkError) -> CalendarEvent {
    try await call {
      switch try await client.calendarGetEventById(.init(path: .init(eventId: id))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "calendar event", identifier: id)
      }
    }
  }

  /// Edits an event in the user's calendar.
  public func editCalendarEvent(id: String, event: EditCalendarEvent) async throws(KTalkError)
    -> CalendarEvent
  {
    try await call {
      switch try await client.calendarEditCalendarEvent(
        .init(path: .init(eventId: id), body: .json(event)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "calendar event", identifier: id)
      }
    }
  }

  /// Fetches the recurring series an event belongs to.
  public func calendarEventRecurrence(id: String) async throws(KTalkError) -> CalendarEvent {
    try await call {
      switch try await client.calendarGetRecurrenceEventById(.init(path: .init(eventId: id))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "calendar event", identifier: id)
      }
    }
  }

  /// Downloads an event as an ICS file, returning the raw bytes.
  public func calendarEventICS(id: String, isExternalCalendar: Bool? = nil)
    async throws(KTalkError) -> Data
  {
    try await call {
      switch try await client.calendarDownloadIcsCalendarFile(
        .init(path: .init(eventId: id), query: .init(isExternalCalendar: isExternalCalendar)))
      {
      case .ok(let ok): return try await Data(collecting: ok.body.any, upTo: .max)
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "calendar event", identifier: id)
      }
    }
  }

  /// Accepts an invitation to an event.
  public func acceptCalendarEvent(id: String) async throws(KTalkError) {
    try await call {
      switch try await client.calendarAcceptEvent(.init(path: .init(eventId: id))) {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "calendar event", identifier: id)
      }
    }
  }

  /// Declines an invitation to an event, optionally notifying the organizer.
  public func rejectCalendarEvent(id: String, withNotification: Bool? = nil)
    async throws(KTalkError)
  {
    try await call {
      switch try await client.calendarRejectEvent(
        .init(path: .init(eventId: id), query: .init(withNotification: withNotification)))
      {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "calendar event", identifier: id)
      }
    }
  }

  /// Cancels an event the user organizes, with an optional message to attendees.
  public func cancelCalendarEvent(id: String, message: String? = nil) async throws(KTalkError) {
    try await call {
      switch try await client.calendarCancelEvent(
        .init(path: .init(eventId: id), query: .init(message: message)))
      {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "calendar event", identifier: id)
      }
    }
  }

  /// Edits an event's attendees.
  public func editCalendarEventAttendees(id: String, attendees: EditCalendarEventAttendees)
    async throws(KTalkError) -> CalendarEvent
  {
    try await call {
      switch try await client.calendarEditAttendee(
        .init(path: .init(eventId: id), body: .json(attendees)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "calendar event", identifier: id)
      }
    }
  }
}
