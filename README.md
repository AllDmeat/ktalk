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
// let recordings = try await client.listRecordings()   // WIP
```

### As a CLI

```sh
export KTALK_BASE_URL="https://example.ktalk.ru"
export KTALK_TOKEN="your-x-auth-token"

ktalk --help
# ktalk recordings list           # WIP
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

_WIP — per-tag tables are added as each SDK section lands._

## CLI Commands

_WIP — command tables are added as each CLI section lands._

## Error Handling

The SDK surfaces a typed `KTalkError` (invalid URL, HTTP status errors, decoding failures,
network errors). _Details WIP._

## Requirements

- Swift 6.2+
- Apple platforms: iOS 18+, macOS 15+ (library). The `ktalk` CLI also builds on Linux and
  Windows.

## License

[MIT](LICENSE)
