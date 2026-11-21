import Foundation
import KTalkSDK
import MCP

/// Read-only tools, each a thin call to one `KTalkClient` method. Every one works with a
/// personal key, which is what an agent acting for one user holds.
let tools: [Tool] = [
  tool(
    "ktalk_list_recordings", "List recordings you can open, newest first.",
    [
      "top": int("Page size"),
      "skip": int("How many to skip"),
      "query": string("Search text"),
      "initiator": bool("Only recordings you started"),
    ]),
  tool(
    "ktalk_get_recording", "Get a recording you can open by key.", ["key": string("Recording key")],
    ["key"]),
  tool(
    "ktalk_get_transcript", "Get a recording's transcript.", ["key": string("Recording key")],
    ["key"]),
  tool(
    "ktalk_get_summary", "Get a recording's summary / protocol.", ["key": string("Recording key")],
    ["key"]),
  tool(
    "ktalk_list_participants", "List a recording's participants.",
    ["key": string("Recording key"), "skip": int("How many to skip"), "top": int("Page size")],
    ["key"]),
  tool(
    "ktalk_list_calendar_events", "List your calendar events from a start date.",
    [
      "start": string("ISO 8601 date or date-time, e.g. 2026-01-02"),
      "end": string("ISO 8601 date or date-time"),
      "take": int("Maximum number of events"),
    ], ["start"]),
  tool(
    "ktalk_get_calendar_event", "Get a calendar event by id.", ["id": string("Event id")], ["id"]),
]

enum ToolError: Error, CustomStringConvertible {
  case missingArgument(String)
  case invalidDate(String)
  case missingEnvironment(String)
  case unknownTool(String)

  var description: String {
    switch self {
    case .missingArgument(let key): "Missing required argument: \(key)"
    case .invalidDate(let value): "Invalid date '\(value)'. Use ISO 8601, e.g. 2026-01-02."
    case .missingEnvironment(let name): "Set \(name) in the MCP server's environment."
    case .unknownTool(let name): "Unknown tool: \(name)"
    }
  }
}

/// Builds the client from the same variables the `ktalk` CLI reads.
func makeClient(environment: [String: String]) throws -> KTalkClient {
  guard let base = environment["KTALK_BASE_URL"], !base.isEmpty else {
    throw ToolError.missingEnvironment("KTALK_BASE_URL")
  }
  guard let token = environment["KTALK_TOKEN"], !token.isEmpty else {
    throw ToolError.missingEnvironment("KTALK_TOKEN")
  }
  return try KTalkClient(baseURL: base, token: token)
}

func handle(
  _ params: CallTool.Parameters, makeClient: @Sendable () throws -> KTalkClient
) async -> CallTool.Result {
  do {
    let text = try await call(params.name, params.arguments ?? [:], client: makeClient())
    return .init(content: [.text(text: text, annotations: nil, _meta: nil)], isError: false)
  } catch {
    let message = (error as? KTalkError)?.localizedDescription ?? "\(error)"
    return .init(content: [.text(text: message, annotations: nil, _meta: nil)], isError: true)
  }
}

func call(_ name: String, _ args: [String: Value], client: KTalkClient) async throws -> String {
  switch name {
  case "ktalk_list_recordings":
    return try json(
      await client.listAccessibleRecordings(
        top: args["top"]?.intValue, skip: args["skip"]?.intValue,
        initiator: args["initiator"]?.boolValue, query: args["query"]?.stringValue))
  case "ktalk_get_recording":
    return try json(await client.accessibleRecording(key: required("key", args)))
  case "ktalk_get_transcript":
    return try json(await client.recordingTranscript(key: required("key", args)))
  case "ktalk_get_summary":
    return try json(await client.recordingSummary(key: required("key", args)))
  case "ktalk_list_participants":
    return try json(
      await client.recordingParticipants(
        key: required("key", args), skip: args["skip"]?.intValue, top: args["top"]?.intValue))
  case "ktalk_list_calendar_events":
    return try json(
      await client.calendarEvents(
        start: date(required("start", args)), end: args["end"]?.stringValue.map(date),
        take: args["take"]?.intValue))
  case "ktalk_get_calendar_event":
    return try json(await client.calendarEvent(id: required("id", args)))
  default:
    throw ToolError.unknownTool(name)
  }
}

// MARK: - Helpers

private func required(_ key: String, _ args: [String: Value]) throws -> String {
  guard let value = args[key]?.stringValue, !value.isEmpty else {
    throw ToolError.missingArgument(key)
  }
  return value
}

func date(_ string: String) throws -> Date {
  let styles = [
    Date.ISO8601FormatStyle(includingFractionalSeconds: true), Date.ISO8601FormatStyle(),
  ]
  for candidate in [string, "\(string)T00:00:00Z"] {
    for style in styles {
      if let date = try? style.parse(candidate) { return date }
    }
  }
  throw ToolError.invalidDate(string)
}

private func json(_ value: some Encodable) throws -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
  encoder.dateEncodingStrategy = .iso8601
  return String(decoding: try encoder.encode(value), as: UTF8.self)
}

private func tool(
  _ name: String, _ description: String, _ properties: [String: Value], _ required: [String] = []
) -> Tool {
  Tool(
    name: name, description: description,
    inputSchema: .object([
      "type": "object",
      "properties": .object(properties),
      "required": .array(required.map { .string($0) }),
    ]),
    annotations: .init(readOnlyHint: true))
}

private func string(_ description: String) -> Value {
  .object(["type": "string", "description": .string(description)])
}

private func int(_ description: String) -> Value {
  .object(["type": "integer", "description": .string(description)])
}

private func bool(_ description: String) -> Value {
  .object(["type": "boolean", "description": .string(description)])
}
