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
are the single source of truth. It is built from Kontur's two published documents — the
public API and the personal access token API — by `scripts/fetch-spec.sh` — do not hand-edit the vendored spec except to remove real data
from examples.

### The vendored spec is normalized, not raw

`openapi/talk.json` is **not** a raw upstream document — `fetch-spec.sh` merges the two and
rewrites the result so the generator accepts it, the generated layer stays warning-free, and
the client tolerates the live API. Every normalization is deterministic (re-fetching unchanged content
stays byte-identical). The complete list of what is changed and why:

1. **`info.version` injected** — upstream omits the OpenAPI-required field, without which the
   generator errors. Set to a constant so re-fetches stay stable.
2. **Integer bounds fixed** — some integer `maximum`/`minimum` are floats or exceed Int64
   (e.g. `9.22e18` on `/api/Kiosk/news`), which OpenAPIKit can't parse. Whole-number floats are
   coerced to ints; out-of-range bounds are dropped. Bounds aren't emitted in the generated
   Swift, so this is codegen-only.
3. **`additionalProperties: false` relaxed** — the live API returns fields the published spec
   hasn't caught up with (e.g. `groupsCount` on users). Strict decoders reject them and fail the
   whole response; removing the flag makes decoding forward-compatible (unknown keys ignored).
4. **Deprecated schema properties removed** — deprecated properties are deleted outright (and
   pulled from `required`) so they never reach the generated model. Deprecated *operations* and
   *parameters* are kept (a deprecated endpoint is still usable), but every residual
   `deprecated` flag is stripped so the generator doesn't emit `@available(*, deprecated)` and
   then reference it in its own coding code, which floods the build with warnings.
5. **Missing path parameters declared** — some paths reference `{param}` without listing it
   (e.g. `qualityName` in the recording-download path); added as required string path params.
6. **Multipart bodies marked `required`** — the generator silently skips optional multipart
   bodies, so uploads (avatars, kiosk artwork) wouldn't generate; marking them required fixes it.
7. **Binary download bodies declared** — the spec leaves the endpoints that return a file
   (`GET …/file/{qualityName}`, the Excel reports, the deepfake-detector source files, the bulk
   recording download, the calendar ICS file) with an
   empty 200, discarding the bytes. A `*/*` binary body is declared — not one concrete type,
   because the server labels files as spreadsheets, archives or media and the runtime rejects
   an undeclared content type.
8. **Drifted response fields made optional** — the refreshed spec newly marks some response
   fields required (`timezone` on both kinds of calendar items) and nobody has confirmed the live API always
   sends them. A missing required field fails the whole response in a strict decoder, so each
   one is listed in `RELAXED_RESPONSE_FIELDS` and dropped from `required`. The list is
   explicit: relaxing every response schema would make non-optional properties of public SDK
   types optional and break consumers.
9. **Support-confirmed recording operation added** — `GET /api/Recordings/{recordingKey}` is
   in neither published document. Kontur.Talk support named it on 2026-10-07 as the way to read
   a recording with a personal access token. It is tagged `x-ktalk-source: support` and added
   only while upstream lacks it under any path casing, so an upstream definition wins — as
   already happened to its sibling `GET /api/recordings`, now in the personal token document.
   The response schema is found by its short name, `*.TalkConferenceRecording`, because
   upstream moves schemas between namespaces.
10. **Personal access token document merged** — Kontur publishes the operations a personal
   access token can call as a second document (`talk.personal-access-token.api`). Its operations
   missing from the public document are added with `x-ktalk-source: personal-token-spec`; where
   both have a route or a schema, the public one wins. Merged operations keep only their 2xx
   responses: every one declares the same error body for 400/401/403/404/429, and the facade
   maps statuses itself. Every operation the document lists gets `x-ktalk-personal-token: true`.
11. **Room file upload body declared** — the personal token document says in prose that
   `POST /api/Rooms/{roomName}/file` takes the file in a multipart form, but declares no body,
   so the client could only send an empty request. A required form with one binary part is
   declared. The part name, `file`, is an assumption not yet checked on a live space.

None of these change the API's wire behaviour — they only fix or complete the description so
codegen works and the client survives real responses. Keep this list in sync with the script.

To apply a new normalization without pulling upstream changes, re-normalize the vendored file:
`SPEC_SOURCE=openapi/talk.json scripts/fetch-spec.sh`. It already holds the personal token
operations; pass `PERSONAL_SPEC_SOURCE=<file>` to merge a personal token document as well.

Workflow:

1. Update or add a spec in `specs/` before implementing new functionality.
2. Implement strictly according to the spec.
3. Keep the README **`## Commands`** table in sync with the CLI. Any PR that adds, removes,
   or renames a `ktalk` command or group MUST update that table in the same PR — it is the
   canonical command list, and it must stay exhaustive. (`ktalk --help` and
   `ktalk <group> --help` are the source of truth to check it against.)

## One API Operation = One CLI Command (hard rule)

Every operation in `openapi/talk.json` is called by exactly one facade method and reached by
exactly one `ktalk` command, and every command reaches exactly one operation. No operation is
left without a command, and no command hides several operations behind a flag — a `v2`
endpoint, a "by type" variant or a personal-key twin is its own command. A facade helper may
build on the method that owns an operation (e.g. `allAccessibleRecordings` pages through
`listAccessibleRecordings`); it must not call the generated client for that operation again.

When the spec gains an operation, the same PR adds its facade method, its command, a
hermetic test and a README **`## Commands`** row. `scripts/check-cli-coverage.sh` enforces
this in CI and fails unless the mapping holds and every command is registered in its group
and the group in `ktalk`. Facade method names must be unique — overloads would make the
mapping ambiguous. The behaviour is specified in [`specs/api-coverage.md`](specs/api-coverage.md).

Each command's abstract starts with the key it takes. There are two kinds of keys:

- `[personal key]` — the personal token document lists the operation (`x-ktalk-personal-token`),
  Kontur.Talk support named it (`x-ktalk-source: support`), or it answered a personal key on a
  live space (`CHECKED_WITH_PERSONAL_KEY` in the coverage script).
- `[space key]` — everything else: the document says a personal token works only with the
  operations it lists.

A personal key acts with its user's rights, so some `[personal key]` commands also need the
user to hold an admin permission; the tag does not say which. `scripts/check-cli-coverage.sh`
fails unless every command starts with the tag its operation implies.

## Architecture

The SDK is layered — keep the layers separate:

1. **Generated** — `types` + `client` produced by `swift-openapi-generator` in the
   `KTalkAPI` target, which `KTalkSDK` re-exports. Never edited by hand.
2. **Facade** — `KTalkClient` and `KTalkClient+<Tag>.swift` extensions: typed errors,
   authentication (`X-Auth-Token`), retries, rate limiting, pagination.
3. **CLI** — the `ktalk` executable, a thin ArgumentParser wrapper that prints JSON.

## Build Quality

- Swift 6 language mode (complete strict concurrency) on every target.
- Warnings are errors on every hand-written target via `.treatAllWarnings(as: .error)` in
  `Package.swift` — not `unsafeFlags`, which would make the library unusable as a SwiftPM
  dependency; SwiftPM ignores warning settings of a dependency. Plain `swift build` enforces
  it, locally and in CI. Keep hand-written code warning-clean.
- The generated layer is the `KTalkAPI` target and is not strict: the generator emits
  warnings we cannot fix (e.g. unused `public import`s). Do not pass a global
  `-Xswiftc -warnings-as-errors` — it would reach `KTalkAPI` too. Warnings caused by the spec
  are still fixed by a deterministic normalization in `scripts/fetch-spec.sh` (as done for
  `deprecated`).
- Format with `swift format --in-place --recursive Sources/ Tests/`; CI lints with
  `swift format lint --strict`.

## Delivery

- One task per pull request.
- Tests are mandatory. They are hermetic: use the `ReplayTransport` test helper with
  synthetic fixtures; never hit the network.
