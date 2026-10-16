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

Kontur publishes what a personal key can call as a separate document,
[Personal API Token](https://developer.kontur.ru/doc/talk.personal-access-token.api).
`scripts/fetch-spec.sh` merges it into `openapi/talk.json` (normalization 10 in `AGENTS.md`).
A command's abstract starts with the key it takes:

| Tag | Meaning |
| --- | ------- |
| `[personal key]` | The document lists the operation, support named it, or it answered a personal key on a live space |
| `[space key]` | Everything else: the document says a personal key works only with what it lists |

A personal key acts with its user's rights. Some `[personal key]` commands, such as
`recordings list` or `users roles`, also need the user to hold an admin permission, and answer
403 otherwise. Methods that work with one recording also check that the user can open it.

`scripts/check-cli-coverage.sh` fails unless every command starts with the tag its operation
implies.

## Recordings with a personal key

| Endpoint | Command | Returns |
| -------- | ------- | ------- |
| `GET /api/Recordings` | `recordings list-accessible` | Recordings the user can open, newest first |
| `GET /api/Recordings/{recordingKey}` | `recordings get-accessible <key>` | One such recording |

`GET /api/Recordings` is in the personal token document. `GET /api/Recordings/{recordingKey}`
is in neither document: Kontur.Talk support named it, and `scripts/fetch-spec.sh` adds it
(normalization 9 in `AGENTS.md`).

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
