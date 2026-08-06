# Contributing

## Prerequisites

- Swift 6.2+ (pinned via [mise](https://mise.jdx.dev): `mise install`).
- On Linux, the URLSession transport needs libcurl: `apt-get install libcurl4-openssl-dev`.

## Everyday commands

```sh
swift build                                   # build the SDK and the ktalk CLI
swift test                                    # run the hermetic test suite
swift build -Xswiftc -warnings-as-errors      # what CI enforces
swift format --in-place --recursive Sources/ Tests/   # auto-format
swift format lint --strict --recursive Sources/ Tests/  # what CI lints
scripts/check-no-internal-data.sh             # the no-internal-data guard
```

## Regenerating the OpenAPI client

The Swift client is generated at build time by `swift-openapi-generator` from the vendored
spec. To refresh the spec from Kontur's published documentation:

```sh
scripts/fetch-spec.sh          # re-downloads openapi/talk.json
swift build                    # regenerates types + client
```

## Rules

- Read [`AGENTS.md`](AGENTS.md) first. Two hard rules: **English only** and **no internal
  data** (no real space names or real API responses anywhere — CI enforces this).
- **One task per pull request.** Keep PRs focused and reviewable.
- Tests are mandatory and hermetic (`ReplayTransport` + synthetic fixtures).
- Any change to the public API must update the README "API Reference" / "CLI Commands"
  sections in the same PR.
