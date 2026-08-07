# Specs

Spec-first development: describe behaviour here before implementing it, and keep these notes in
sync with the code. See [`AGENTS.md`](../AGENTS.md) for the workflow and hard rules.

## Source of truth

- **`openapi/talk.json`** — the vendored Kontur.Talk OpenAPI document, fetched and normalized by
  [`scripts/fetch-spec.sh`](../scripts/fetch-spec.sh). It is the source of truth for the
  generated `types` + `client` layer. Do not hand-edit it except to remove real data from
  examples; add normalizations to the fetch script instead so they survive a refresh.

## Layers

1. **Generated** — `types` + `client` from `swift-openapi-generator` (machine output).
2. **Facade** — `KTalkClient` + `KTalkClient+<Tag>.swift`: typed errors, auth, retries,
   pagination. One extension file per API tag.
3. **CLI** — the `ktalk` executable, a thin ArgumentParser wrapper that prints JSON.

## Adding a tag

1. Find the generated operation names in the build output (`.build/.../GeneratedSources`).
2. Add `KTalkClient+<Tag>.swift` with public typealiases over the generated types and ergonomic
   methods that map `.ok` / `.undocumented` to typed results and ``KTalkError``.
3. Add `Sources/ktalk/<Tag>/…Command.swift` and register the group in `KTalk.swift`.
4. Add hermetic tests using `ReplayTransport` + synthetic fixtures.
5. Update the README "API Reference" and "CLI Commands" tables.
