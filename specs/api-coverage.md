# API coverage and key kinds

What the CLI exposes, which key each command takes, and how recordings are read with a
personal key. Rules for contributors are in [`AGENTS.md`](../AGENTS.md).

## One operation, one command

Each operation in `openapi/talk.json` has exactly one `ktalk` command, and each command calls
exactly one operation. `scripts/check-cli-coverage.sh` checks this in CI.

## Two kinds of keys

| Key | Where it is created | What it acts as |
| --- | ------------------- | --------------- |
| Space key | Admin panel → API keys, by a space admin | The whole space, within the scopes the admin grants |
| Personal key | Profile → Settings → API keys | Its user, with that user's rights |

A command's abstract starts with the key it takes:

- `[personal key]` — checked against a live space: works with a personal key.
- `[space key]` — checked against a live space: a personal key gets 403.
- No tag — the command changes data and has not been checked with a personal key.

## Recordings with a personal key

The personal key gets 403 on every `/api/Domain/...` endpoint. Kontur.Talk support named two
endpoints that work with it; neither is in the published spec, so `scripts/fetch-spec.sh` adds
them (normalization 9 in `AGENTS.md`):

| Endpoint | Command | Returns |
| -------- | ------- | ------- |
| `GET /api/recordings` | `recordings list-accessible` | Recordings the user can open, newest first |
| `GET /api/Recordings/{recordingKey}` | `recordings get-accessible <key>` | One such recording |

Transcript, summary and artifacts (`recordings transcript`, `summary`, `summary-by-type`,
`artifacts`) are in the published spec and work with either key.

### Paging `list-accessible`

Measured on a live space, 2026-10-07:

- `top` — page size, 1 to 100; the server defaults to 10 and answers 400 above 100. The CLI
  rejects an out-of-range `--top` before sending.
- `skip` — offset. A `skip` past the end returns an empty page.
- No total and no cursor in the response.

`--all` fetches every page itself and therefore rejects `--top` and `--skip`. It requests pages
of 100 until a page is empty, skips recordings it has already seen by id, and stops when a page
brings nothing new — so a server that caps the page size loses nothing and a server that
ignores `skip` cannot loop forever.
