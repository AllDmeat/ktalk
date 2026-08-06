# KTalkSDK — Development Guidelines

## Language Policy

**English only.** All content in this repository MUST be in English: code, comments,
documentation, commit messages, PR titles and descriptions, specs, READMEs, and YAML
descriptions in the OpenAPI spec. No exceptions.

## No Internal Data (hard rule)

This is a public repository. It MUST NOT contain:

- The name of any real Kontur.Talk space (workspace subdomain).
- Any real API-response data, recording keys, user records, emails, or tokens captured
  from a live space.

Use only synthetic placeholders in code, tests, fixtures, and docs:

- Space / base URL: `example` / `https://example.ktalk.ru`
- Tokens: obviously fake values such as `test-token`
- Fixtures: hand-authored synthetic JSON, never captured from the real API.

`scripts/check-no-internal-data.sh` enforces this and runs in CI. Do not weaken it.

## Spec-First Development

The vendored OpenAPI document (`openapi/talk.json`) and the specifications in `specs/`
are the single source of truth. It is fetched from Kontur's published documentation via
`scripts/fetch-spec.sh` — do not hand-edit the vendored spec except to remove real data
from examples.

Workflow:

1. Update or add a spec in `specs/` before implementing new functionality.
2. Implement strictly according to the spec.
3. Keep the README "API Reference" and "CLI Commands" sections in sync. Any PR that
   changes the public API surface MUST update them.

## Architecture

The SDK is layered — keep the layers separate:

1. **Generated** — `types` + `client` produced by `swift-openapi-generator` into a
   gitignored `Sources/KTalkSDK/GeneratedSources/`. Never edited by hand.
2. **Facade** — `KTalkClient` and `KTalkClient+<Tag>.swift` extensions: typed errors,
   authentication (`X-Auth-Token`), retries, rate limiting, pagination.
3. **CLI** — the `ktalk` executable, a thin ArgumentParser wrapper that prints JSON.

## Build Quality

- Swift 6 language mode (complete strict concurrency) on every target.
- Warnings are treated as errors **in CI** (`swift build -Xswiftc -warnings-as-errors`),
  not via `unsafeFlags` in the manifest — that would make the library unusable as a
  SwiftPM dependency. Keep hand-written code warning-clean.
- If the generated layer ever emits a warning, scope-suppress it for the generated target
  only and document why here.
- Format with `swift format --in-place --recursive Sources/ Tests/`; CI lints with
  `swift format lint --strict`.

## Delivery

- One task per pull request.
- Tests are mandatory. They are hermetic: use the `ReplayTransport` test helper with
  synthetic fixtures; never hit the network.
