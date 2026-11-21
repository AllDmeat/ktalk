# MCP server

`ktalk-mcp` is a second executable in this package. It serves the Kontur.Talk API to AI agents
over the [Model Context Protocol](https://modelcontextprotocol.io) on stdio.

## Requirements

- **Thin.** Each tool calls exactly one `KTalkClient` facade method and returns its result
  encoded as JSON, the same encoding `ktalk` prints. The server never calls the generated
  client directly, so "one operation = one CLI command" (see [`api-coverage.md`](api-coverage.md))
  is not affected: the MCP is another consumer of the facade, not another path to an operation.
- **Read-only.** Every tool is annotated `readOnlyHint: true`. Tools that change data are out of
  scope until a separate spec defines how they are confirmed.
- **Personal key.** Every tool reaches an operation tagged `[personal key]`, so an agent holding
  one user's key can call all of them.
- **Credentials** come from `KTALK_BASE_URL` and `KTALK_TOKEN` in the server's environment, the
  same variables the CLI reads. The server starts without them; a tool call then returns an
  error naming the missing variable.
- **Errors** — a missing argument, an unknown tool or a `KTalkError` — are returned as a tool
  result with `isError: true`, never as a crash.
- **Version** is `KTalkSDK.version`, the value the release stamps from the tag.
- **Release.** The `ktalk-mcp` binary ships in the same per-platform archive as `ktalk`, so one
  `mise use github:AllDmeat/ktalk` installs both. No new asset names: the Gemini extension
  archives are matched by name.

## Tools

| Tool | Facade method |
|---|---|
| `ktalk_list_recordings` | `listAccessibleRecordings` |
| `ktalk_get_recording` | `accessibleRecording` |
| `ktalk_get_transcript` | `recordingTranscript` |
| `ktalk_get_summary` | `recordingSummary` |
| `ktalk_list_participants` | `recordingParticipants` |
| `ktalk_list_calendar_events` | `calendarEvents` |
| `ktalk_get_calendar_event` | `calendarEvent` |

A PR that adds, removes or renames a tool updates this table and the README **`## MCP server`**
section in the same PR.
