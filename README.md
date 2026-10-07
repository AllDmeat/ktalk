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

This installs the latest release binary for your platform (macOS, Linux) via mise's
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

`ktalk` needs your space URL and an `X-Auth-Token` key. Set them once in the environment:

```sh
export KTALK_BASE_URL="https://example.ktalk.ru"
export KTALK_TOKEN="your-x-auth-token"
```

Kontur.Talk issues two kinds of keys, and they see different recordings:

| Key | Where to create it | What it reads |
| --- | ------------------ | ------------- |
| Space key | Admin panel → **API keys**, by a space admin | Every recording in the space, plus whatever other scopes the admin grants |
| Personal key | Your profile → **Settings** → **API keys** | What you can see yourself: the recordings you can open, user search, rooms |

Each command's `--help` starts with the key it takes: `[personal key]` works with a personal
key, `[space key]` answers `403` to one. Commands that change data are untagged — they have not
been checked with a personal key.

Every command also accepts `--base-url` / `--token` to override per-invocation.

## Usage

```sh
ktalk --help                                  # list all command groups
ktalk recordings --help                       # help for a group

ktalk recordings list --limit 20              # space key: JSON to stdout
ktalk recordings list --all | jq '.[].key'    # space key: follow all pages, pipe to jq
ktalk recordings list-accessible --all | jq '.[].id'  # personal key: your recordings
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
| `recordings` | `list [--page-token --limit --query --all]`, `list-v1 [--start-from --start-to --skip --top --query --title --max-participant-count --order-mode]`, `get <key>`, `list-accessible [--top --skip --all]`, `get-accessible <key>`, `participants <key> [--skip --top]`, `transcript <key> [--format --no-timestamps]`, `summary <key>`, `summary-by-type <key> <type>`, `artifacts <key>`, `download <key> -o <path> [--quality]`, `current --room [--session-hall]`, `start --from-json`, `edit <key> --from-json`, `delete <key> [--force]`, `access <key>`, `set-access <key> --from-json`, `set-immutable <key>`, `unset-immutable <key>` |
| `rooms` | `get <name>`, `update <name> --from-json`, `lock <name> --from-json`, `end-conference <name>`, `add-moderator <name> <user-ref>`, `remove-moderator <name> <user-ref>`, `set-anonymous-access <name> --from-json`, `notify-call <name> --from-json`, `cancel-call <name> --from-json` |
| `meetings` | `list <email> --start [--end --take]`, `create <email> --from-json`, `edit <email> <event-id> --from-json`, `cancel <email> <event-id> [--message]`, `edit-attendees <email> <event-id> --from-json`, `recurrence <email> <event-id>` |
| `reports` | `audit-log --start --end`, `conferences [--from --to --skip --take --room]`, `conference <key>`, `conference-enriched <key>`, `participants <key>`, `activity <key> [--skip --take]`, `chat <key> [--skip --take]`, `room <name> --from [--to]`, `questions <key> -o <path>`, `attendance --from -o <path> [--to]` |
| `users` | `search [--query --email --role --skip --top --include-disabled --include-guests]`, `scan [--offset --top --role --include-disabled --include-guests]`, `get <key>`, `create-or-update --from-json`, `delete <key>`, `revoke-sessions <key>`, `roles <key>`, `change-roles <key> --from-json`, `set-permissions <key> --from-json`, `upload-avatar <key> <file> [--content-type]`, `delete-avatar <key>`, `sync-avatar <key>` |
| `roles` | `list`, `get <id>`, `create --from-json`, `update <id> --from-json`, `delete <id>`, `permissions`, `defaults`, `default`, `set-default --from-json`, `default-by-type <type>`, `set-default-by-type <type> --from-json` |
| `webhooks` | `list`, `create --from-json`, `activate <webhook-key> --from-json`, `delete <webhook-key>` |
| `stats` | `domain [--start --end]`, `registered-users`, `conferences [--from --to]`, `recordings [--start --end]`, `kiosks [--start --end]`, `online`, `conferences-online`, `recordings-online`, `kiosks-online`, `streams-online`, `recordings-size`, `whiteboards`, `deepfake`, `tariff` |
| `surveys` | `list`, `get <id>`, `create --from-json`, `update <id> --from-json`, `publish <id>`, `unpublish <id>` |
| `kiosks` | `list`, `get <id>`, `create --from-json`, `update <id> --from-json`, `delete <id>`, `search`, `gadgets`, `news`, `screensavers`, `wallpapers`, `count [--search --status --status-value --version --offset --page-size --group]`, `versions`, `block <id>`, `unblock <id>`, `equipment-check <id>`, `current-event <id>`, `groups`, `create-group --from-json`, `update-group <key> --from-json`, `delete-group <key>`, `move --from-json`, `mass-update --from-json`, `add-notification-unit --from-json`, `remove-notification-unit --from-json`, `upload-screensavers <files> ... [--content-type]`, `delete-screensaver <key>`, `upload-wallpapers <files> ... [--content-type]`, `delete-wallpaper <key>`, `set-default-wallpapers --from-json` |
| `calendar-servers` | `list [--skip --take]`, `get <id>`, `add --from-json`, `update <id> --from-json`, `delete <id>` |
| `deepfake` | `report <conference-key> [--timezone]`, `statistic`, `task-file <conference-key> <task-key> -o <path>`, `task-files <conference-key> -o <path>` |
| `api-keys` | `list`, `access-info` |
| `telemetry` | `list [--from --to --take --page-token]`, `list-v1 [--from --to --take --page-token]` |

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
  builds on Linux.

## License

[MIT](LICENSE)
