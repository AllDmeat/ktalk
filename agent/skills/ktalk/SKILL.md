---
name: ktalk
description: Read and work with Kontur.Talk (ktalk.ru video-conferencing / meetings platform) through the `ktalk` CLI — recordings, transcripts and summaries, rooms, calendar meetings, conference reports and history, users, roles, webhooks, statistics, surveys, kiosks, calendar servers, deepfake detection, and API keys. Use this skill whenever Kontur.Talk comes up in any form, and do not wait for a perfectly-phrased request — it applies to a `<space>.ktalk.ru` URL, a recording key, "what recordings do I have", "download the transcript of yesterday's sync", "get the summary of that meeting", "who was in the call", managing rooms/webhooks/users, reading conference stats, and any invocation of the `ktalk` command itself. It applies when the user never types "Kontur.Talk" but is plainly talking about their Talk space. It does NOT apply to other conferencing tools — Zoom, Google Meet, Microsoft Teams, Webex, Jitsi — which share the meeting/recording/room vocabulary but are different products, and it is not about Kaiten or any project tracker. The CLI has a grouped-but-large command surface whose exact names and flags cannot be guessed, so this skill exists to make you read its `--help` first and work from what it says instead of inventing commands.
---

# ktalk

`ktalk` is a CLI over the [Kontur.Talk](https://ktalk.ru) API. Commands are grouped by API tag
(`recordings`, `rooms`, `meetings`, `reports`, `users`, `roles`, `webhooks`, `stats`, `surveys`,
`kiosks`, `calendar-servers`, `deepfake`, `api-keys`), each with subcommands. Every command prints
JSON. There is no interactive mode.

## Read the help before you type a command

The groups are guessable; the subcommands and their flags are not, and releases add more. Read the
help first — it is instant, needs no credentials, and makes no network calls:

```bash
ktalk --help                     # every group
ktalk <group> --help             # a group's subcommands
ktalk <group> <command> --help   # a command's exact flags, before its first use
```

The help outranks this file: where they disagree, the help is current and this is stale. Don't paste
flags from here — get them from `--help`.

## Go through `ktalk`, not around it

Route every read and write through the CLI; do not `curl` the API or hand-roll a client. It already
handles the `X-Auth-Token` header, `429` back-off (shared across requests — add no `sleep`/retry
loops), cursor pagination, and the API's mixed date formats. Companions are `jq` and shell. If no
command exists for the task, say so rather than improvising a raw call.

## Credentials and scopes

Auth is two environment variables (no config file); `--base-url` / `--token` override per command:

```bash
export KTALK_BASE_URL="https://<space>.ktalk.ru"
export KTALK_TOKEN="<x-auth-token>"   # admin panel → API keys; never echo it
```

Keys are scoped: a read-only key returns **`Forbidden` (403)** on writes. `ktalk api-keys
access-info` shows what the current key allows — a 403 is a permissions fact, not a bug to retry
around. Read auth failures rather than working around them; a rejected request fails the same way
twice.

## Keys, pagination, transcripts

- You start with no keys — list to find them (`ktalk recordings list`, `ktalk users search --query
  …`), and match a specific recording on `title`/`createdDate` with `jq` rather than guessing a key.
- `recordings list` is cursor-paginated (`{items, nextPageToken}`); pass `--all` to follow every page
  or feed `nextPageToken` back via `--page-token`. Don't assume one page is everything.
- A recording's artifacts are its **transcript**, **summary**, and **media file**. Add `--format
  text` to `recordings transcript` for a readable speaker dialogue instead of raw JSON.
- Write commands take their body as a file: `--from-json <path>` (see the command's `--help`).
- Don't read a fact out of a missing field — an absent `participants` key doesn't mean there were
  none; fetch the endpoint that carries it (e.g. `reports participants <key>`).

## Small things that bite

- Dates are ISO 8601; date-only `2026-01-02` is accepted.
- `delete` / `end-conference` / `revoke-sessions` act immediately — no undo. Confirm first.
- Rooms are addressed by `roomName` (the URL slug), not an id.

## If the CLI is missing

Install with [mise](https://mise.jdx.dev) — `mise use github:AllDmeat/ktalk` — or grab a
binary from [Releases](https://github.com/AllDmeat/ktalk/releases). Don't `curl` the API instead, and
don't build from source (that's the contributor flow).
