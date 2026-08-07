# ktalk

`ktalk` is a command-line tool for the [Kontur.Talk](https://ktalk.ru) API. It talks to your
space over the integrator HTTP API and prints JSON — pipe it into `jq`, scripts, or anything
else. (A Swift SDK powers it and is available as a library too — see [Library](#library-bonus).)

## Install

### mise (recommended)

```sh
mise use github:AllDmeat/ktalk
ktalk --help
```

This installs the latest release binary for your platform (macOS, Linux, Windows) via mise's
GitHub backend. Add `-g` for a global install; pin a version with `github:AllDmeat/ktalk@1.0.0`.

### Release binary

Download the archive for your platform from
[Releases](https://github.com/AllDmeat/ktalk/releases), extract it, and put `ktalk` on your
`PATH`.

### From source

```sh
git clone https://github.com/AllDmeat/ktalk && cd ktalk
swift build -c release        # binary at .build/release/ktalk
```

## Authenticate

`ktalk` needs your space URL and an `X-Auth-Token` API key (created in the Kontur.Talk admin
panel under **API keys**). Set them once in the environment:

```sh
export KTALK_BASE_URL="https://example.ktalk.ru"
export KTALK_TOKEN="your-x-auth-token"
```

Every command also accepts `--base-url` / `--token` to override per-invocation.

## Usage

```sh
ktalk --help                                  # list all command groups
ktalk recordings --help                       # help for a group

ktalk recordings list --limit 20              # JSON to stdout
ktalk recordings list --all | jq '.[].key'    # follow all pages, pipe to jq
ktalk recordings transcript <recordingKey>              # raw JSON
ktalk recordings transcript <recordingKey> --format text  # readable speaker dialogue
ktalk recordings summary <recordingKey>
ktalk recordings download <recordingKey> --quality source -o meeting.mp4

ktalk rooms get <roomName>
ktalk reports conferences --from 2026-01-01 --to 2026-02-01
ktalk users search --query ivanov
ktalk stats online
ktalk api-keys access-info                    # what your token can do
```

Commands that send a request body take it as a JSON file with `--from-json <path>` (so you
never wrestle dozens of flags):

```sh
ktalk webhooks create --from-json hook.json
ktalk rooms update demo --from-json room.json
```

## Commands

Output is always JSON. `<key>` / `<id>` / `<name>` are positional; `--from-json` points at a
request-body file.

| Group | Commands |
| ----- | -------- |
| `recordings` | `list [--all --limit --page-token --query]`, `get <key>`, `transcript <key>`, `summary <key>`, `download <key> [--quality] -o <path>` |
| `rooms` | `get <name>`, `update <name> --from-json`, `lock <name> --from-json`, `end-conference <name>`, `add-moderator <name> <userRef>`, `remove-moderator <name> <userRef>` |
| `meetings` | `list <email> --start [--end --take]`, `create <email> --from-json`, `edit <email> <eventId> --from-json`, `cancel <email> <eventId> [--message]`, `edit-attendees <email> <eventId> --from-json`, `recurrence <email> <eventId>` |
| `reports` | `audit-log --start --end`, `conferences [--from --to --skip --take --room]`, `conference <key>`, `conference-enriched <key>`, `participants <key>`, `activity <key>`, `chat <key>`, `room <name> --from [--to]` |
| `users` | `search […]`, `scan […]`, `get <key>`, `create-or-update --from-json`, `delete <key>`, `revoke-sessions <key>`, `roles <key>`, `change-roles <key> --from-json`, `set-permissions <key> --from-json` |
| `roles` | `list`, `get <id>`, `create --from-json`, `update <id> --from-json`, `delete <id>`, `permissions`, `defaults` |
| `webhooks` | `list`, `create --from-json`, `activate <key> --from-json`, `delete <key>` |
| `stats` | `domain`, `registered-users`, `conferences`, `recordings`, `kiosks`, `online`, `conferences-online`, `recordings-online`, `kiosks-online`, `streams-online`, `recordings-size`, `whiteboards`, `deepfake`, `tariff` |
| `surveys` | `list`, `get <id>`, `create --from-json`, `update <id> --from-json`, `publish <id>`, `unpublish <id>` |
| `kiosks` | `list`, `get <id>`, `create --from-json`, `update <id> --from-json`, `delete <id>`, `search`, `gadgets`, `news`, `screensavers`, `wallpapers` |
| `calendar-servers` | `list [--skip --take]`, `get <id>`, `add --from-json`, `update <id> --from-json`, `delete <id>` |
| `deepfake` | `report <conferenceKey> [--timezone]`, `statistic` |
| `api-keys` | `list`, `access-info` |

Note: your token's scopes decide what works — read-only keys can `list`/`get` but `403` on
writes. Run `ktalk api-keys access-info` to see what yours allows.

## Library (bonus)

The same functionality is available as a Swift package, `KTalkSDK` (iOS 18+, macOS 15+), if you'd
rather call it from code than shell out.

```swift
// Package.swift
.package(url: "https://github.com/AllDmeat/ktalk", from: "0.1.0")
```

```swift
import KTalkSDK

let client = try KTalkClient(baseURL: "https://example.ktalk.ru", token: myToken)
let page = try await client.listRecordings(limit: 20)
for recording in page.items { print(recording.key ?? "", recording.title ?? "") }
```

Every CLI command maps to a `KTalkClient` method (`listRecordings`, `room(name:)`,
`createWebhook`, …). Failures surface as a typed `KTalkError`. The full method list is in the
[DocC docs](Sources/KTalkSDK/Documentation.docc) and mirrors the command groups above.

## Agent skill

Coding agents guess CLI invocations badly. This repository ships a skill that makes the agent read
`ktalk --help` and `ktalk <group> <command> --help` before composing anything, and adds what the
help cannot tell it — env-var auth, token scopes, cursor pagination, a recording's artifacts
(transcript / summary / media), `transcript --format text`, and built-in `429` handling. One copy of
that guidance lives in [`agent/skills/ktalk/`](agent/skills/ktalk); all three hosts read it from
there.

### Claude Code

```
/plugin marketplace add AllDmeat/ktalk
/plugin install ktalk@ktalk
```

Then restart or run `/reload-plugins`. Update later with `/plugin marketplace update ktalk` and
`/plugin update ktalk@ktalk`. The same commands work outside the REPL as `claude plugin …`.

### Cursor

Cursor 2.5+ reads plugins from a marketplace repository, and this repo is one — see
[`.cursor-plugin/marketplace.json`](.cursor-plugin/marketplace.json). Add it with `/add-plugin` in
the editor, or register the repo team-wide under Dashboard → Settings → Plugins → Team Marketplaces
by pasting `https://github.com/AllDmeat/ktalk`. Cursor reads the skill from `agent/skills/` and the
rules from [`agent/rules/`](agent/rules).

### Gemini CLI

```bash
gemini extensions install https://github.com/AllDmeat/ktalk
```

Gemini installs an extension from its own root directory and cannot install a subdirectory straight
from GitHub, so each release ships [`agent/`](agent) as a self-contained archive asset and Gemini
takes that. Update with `gemini extensions update ktalk`.

## Development

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`AGENTS.md`](AGENTS.md).

```sh
swift build && swift test
swift build -Xswiftc -warnings-as-errors        # the CI gate
swift format lint --strict --recursive Sources/ Tests/
scripts/fetch-spec.sh                            # refresh the vendored OpenAPI
```

The SDK is generated from the vendored OpenAPI document — a **normalized copy** of Kontur's
published spec, not the raw upstream (see [`AGENTS.md`](AGENTS.md) for every fixup and why). A
weekly workflow refreshes it,
classifies changes with [oasdiff](https://github.com/oasdiff/oasdiff) (non-breaking → auto-merged
minor release, breaking → a `major` PR for review), and cuts a release. To let the auto-tag
trigger the Release workflow, add a `RELEASE_PAT` repository secret.

## Requirements

- Running the CLI: nothing — the release binary is self-contained.
- Building / using the library: Swift 6.2+. Library platforms iOS 18+ / macOS 15+; the CLI also
  builds on Linux and Windows.

## License

[MIT](LICENSE)
