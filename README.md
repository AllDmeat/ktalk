# ktalk-sdk

A Swift SDK and `ktalk` command-line tool for the [Kontur.Talk](https://ktalk.ru) integrator
HTTP API, generated from its published [OpenAPI specification](https://developer.kontur.ru/doc/talk.public.api).

- **`KTalkSDK`** — a typed Swift client (iOS 18+, macOS 15+) layered over a
  `swift-openapi-generator` core, with authentication, retries, and typed errors.
- **`ktalk`** — a thin command-line wrapper over the SDK that prints JSON (macOS/Linux/Windows).

> **Status: work in progress.** The package scaffold, SDK core, and per-tag commands land in
> separate pull requests. Sections marked _WIP_ below are filled in as those land.

## Installation

### As a library

```swift
// Package.swift
.package(url: "https://github.com/AllDmeat/ktalk-sdk", from: "0.1.0")
```

```swift
.target(name: "MyApp", dependencies: [.product(name: "KTalkSDK", package: "ktalk-sdk")])
```

### CLI via mise

```sh
mise use -g "github:AllDmeat/ktalk-sdk"   # once releases are published
```

### CLI from a release binary

Download the archive for your platform from
[Releases](https://github.com/AllDmeat/ktalk-sdk/releases) and put `ktalk` on your `PATH`.

## Quick start

### As a library

```swift
import KTalkSDK

let client = try KTalkClient(
  baseURL: "https://example.ktalk.ru",
  token: ProcessInfo.processInfo.environment["KTALK_TOKEN"]!
)
let page = try await client.listRecordings(limit: 20)
for recording in page.items {
  print(recording.key ?? "", recording.title ?? "")
}
```

### As a CLI

```sh
export KTALK_BASE_URL="https://example.ktalk.ru"
export KTALK_TOKEN="your-x-auth-token"

ktalk --help
ktalk recordings list --limit 20
ktalk recordings get <recordingKey>
ktalk recordings transcript <recordingKey>
ktalk recordings summary <recordingKey>
ktalk recordings download <recordingKey> --quality source -o out.mp4
```

## Configuration

The SDK takes `baseURL` and `token` explicitly. The CLI reads them from the environment,
overridable per-invocation with flags:

| Setting  | Environment      | Flag          |
| -------- | ---------------- | ------------- |
| Base URL | `KTALK_BASE_URL` | `--base-url`  |
| Token    | `KTALK_TOKEN`    | `--token`     |

Authentication uses an admin-issued API key sent in the `X-Auth-Token` header. Create one in
the Kontur.Talk admin panel under **API keys**. There is no config file.

## API Reference

More tags are added as each SDK section lands.

### Recordings

| Method | Description |
| ------ | ----------- |
| `listRecordings(pageToken:limit:query:)` | List recordings (one `Page<Recording>`). |
| `collectAll { listRecordings(pageToken:) }` | Fetch every page as a flat array. |
| `recording(key:)` | Fetch a single `Recording`. |
| `recordingTranscript(key:)` | Fetch a recording's transcript. |
| `recordingSummary(key:)` | Fetch a recording's summary / protocol. |
| `downloadRecording(key:quality:)` | Download the media file as `Data`. |

### Rooms

| Method | Description |
| ------ | ----------- |
| `room(name:)` | Fetch a `Room`. |
| `updateRoom(name:params:)` | Create or update a room. |
| `endConference(roomName:)` | Forcibly end the conference. |
| `setRoomLock(roomName:request:)` | Set or clear the PIN and masking. |
| `addModerator(roomName:userRef:)` / `removeModerator(roomName:userRef:)` | Manage moderators. |

## CLI Commands

More command groups are added as each CLI section lands.

### `ktalk recordings`

| Command | Description |
| ------- | ----------- |
| `list [--all] [--limit N] [--page-token T] [--query Q]` | List recordings (a page, or all with `--all`). |
| `get <key>` | Print a recording as JSON. |
| `transcript <key>` | Print a recording's transcript. |
| `summary <key>` | Print a recording's summary / protocol. |
| `download <key> [--quality source] -o <path>` | Download the media file to `<path>`. |

### `ktalk rooms`

| Command | Description |
| ------- | ----------- |
| `get <name>` | Print a room as JSON. |
| `update <name> --from-json <path>` | Create/update a room from a params file. |
| `lock <name> --from-json <path>` | Set/clear PIN + masking from a request file. |
| `end-conference <name>` | Forcibly end the conference. |
| `add-moderator <name> <userRef>` / `remove-moderator <name> <userRef>` | Manage moderators. |

## Error Handling

The SDK surfaces a typed `KTalkError` (invalid URL, HTTP status errors, decoding failures,
network errors). _Details WIP._

## Development

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`AGENTS.md`](AGENTS.md). Common commands:

```sh
swift build && swift test
swift build -Xswiftc -warnings-as-errors        # the CI gate
swift format lint --strict --recursive Sources/ Tests/
scripts/check-no-internal-data.sh
scripts/fetch-spec.sh                            # refresh the vendored OpenAPI
```

The SDK is layered — generated core → `KTalkClient` facade → `ktalk` CLI — and documented with
DocC (`Sources/KTalkSDK/Documentation.docc`). Spec normalizations live in `scripts/fetch-spec.sh`;
see [`specs/`](specs/) and the [constitution](.specify/memory/constitution.md).

### Automated updates

A weekly workflow refreshes the OpenAPI document, classifies the change with
[oasdiff](https://github.com/oasdiff/oasdiff), and opens a PR: non-breaking changes are labeled
`minor` and auto-merged once CI is green; breaking changes are labeled `major` and left for
review. Merging tags a release. To let the auto-tag trigger the Release workflow, add a
`RELEASE_PAT` repository secret (a token with `contents: write`); without it the tag is still
created and Release can be re-run.

## Requirements

- Swift 6.2+
- Apple platforms: iOS 18+, macOS 15+ (library). The `ktalk` CLI also builds on Linux and
  Windows.

## License

[MIT](LICENSE)
