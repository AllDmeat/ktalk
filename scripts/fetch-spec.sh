#!/usr/bin/env bash
# Fetches the published Kontur.Talk OpenAPI document and vendors it at openapi/talk.json.
#
# The document is public and uses the {space} placeholder for the workspace host, so it
# contains no workspace-specific data. Run `swift build` afterwards to regenerate the client.
set -euo pipefail

SPEC_URL="https://developer.kontur.ru/api/documentations/talk.public.api/file"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$REPO_ROOT/openapi/talk.json}"

mkdir -p "$(dirname "$OUT")"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

echo "Fetching $SPEC_URL"
curl -fsSL "$SPEC_URL" -o "$tmp"

# Normalize and pretty-print for a stable, diff-friendly checked-in file.
# The published document omits the OpenAPI-required `info.version`; inject a stable
# placeholder so swift-openapi-generator accepts it. The value is constant so repeated
# fetches of unchanged content stay byte-identical (the weekly updater relies on that).
python3 - "$tmp" "$OUT" <<'PY'
import json
import re
import sys

HTTP_METHODS = ("get", "put", "post", "delete", "patch", "options", "head", "trace")
INT64_MAX = 2**63 - 1
INT64_MIN = -(2**63)
BOUND_KEYS = ("maximum", "minimum")


def normalize_int_bounds(node):
    """Make integer-schema numeric bounds parseable by OpenAPIKit.

    The published document expresses some integer `maximum` values as floats in
    exponential form (e.g. 9.22e18) that also overflow Int64. OpenAPIKit requires an
    integer literal for integer schemas. Coerce whole-number floats to ints; drop bounds
    outside Int64 range. Numeric bounds are validation-only and are not emitted in the
    generated Swift, so this does not change the generated client.
    """
    if isinstance(node, dict):
        if node.get("type") == "integer":
            for key in BOUND_KEYS:
                if key not in node:
                    continue
                value = node[key]
                if isinstance(value, bool):
                    continue
                if isinstance(value, float):
                    value = int(value)
                if isinstance(value, int) and INT64_MIN <= value <= INT64_MAX:
                    node[key] = value
                else:
                    del node[key]
        for child in node.values():
            normalize_int_bounds(child)
    elif isinstance(node, list):
        for child in node:
            normalize_int_bounds(child)


def relax_additional_properties(node):
    """Drop `additionalProperties: false` so decoding tolerates unknown fields.

    The live API returns fields the published spec has not caught up with (e.g. an extra
    `groupsCount` on user objects). With `additionalProperties: false`, the generator emits
    strict decoders that reject those unknown keys and fail the whole response. Removing the
    flag makes the generated types forward-compatible: unknown keys are ignored. Only the
    boolean-`false` form is removed; schema-valued `additionalProperties` (typed maps) stay.
    """
    if isinstance(node, dict):
        if node.get("additionalProperties") is False:
            del node["additionalProperties"]
        for child in node.values():
            relax_additional_properties(child)
    elif isinstance(node, list):
        for child in node:
            relax_additional_properties(child)


def strip_deprecated(node):
    """Drop deprecated members from the document, and strip any residual `deprecated` flag.

    Deprecated schema *properties* are removed outright (not just unmarked) so they never
    reach the generated model — the property is deleted and pulled from any `required` list.

    Deprecated *operations* and *parameters* are kept (removing an endpoint would break the
    facades that call it, and a deprecated endpoint is still usable) — only their
    `deprecated` flag is stripped. A whole schema *definition* can also carry
    `deprecated: true`; it cannot be deleted without breaking the `$ref`s that point at it,
    so its flag is stripped too. Either way no `deprecated` flag survives, which is what
    keeps the strict build clean (the generator otherwise emits `@available(*, deprecated)`
    and then references those members in its own coding code, tripping `-warnings-as-errors`).

    `deprecated` is only acted on when it is a boolean flag, never when it is a schema
    property literally named `deprecated`.
    """
    _remove_deprecated_properties(node)
    _strip_deprecated_flags(node)


def _remove_deprecated_properties(node):
    if isinstance(node, dict):
        properties = node.get("properties")
        if isinstance(properties, dict):
            removed = [
                name
                for name, schema in properties.items()
                if isinstance(schema, dict) and schema.get("deprecated") is True
            ]
            for name in removed:
                del properties[name]
            required = node.get("required")
            if removed and isinstance(required, list):
                node["required"] = [name for name in required if name not in removed]

        for child in node.values():
            _remove_deprecated_properties(child)
    elif isinstance(node, list):
        for child in node:
            _remove_deprecated_properties(child)


def _strip_deprecated_flags(node):
    if isinstance(node, dict):
        if isinstance(node.get("deprecated"), bool):
            del node["deprecated"]
        for child in node.values():
            _strip_deprecated_flags(child)
    elif isinstance(node, list):
        for child in node:
            _strip_deprecated_flags(child)


def ensure_path_parameters(doc):
    """Declare path parameters that appear in a path template but are missing.

    Some operations reference `{param}` in the path without listing it under `parameters`
    (e.g. `qualityName` in `/api/Recordings/{recordingKey}/file/{qualityName}`), which the
    generator rejects. Add the missing declarations at the path-item level as required
    string path parameters.
    """
    for path, item in (doc.get("paths") or {}).items():
        if not isinstance(item, dict):
            continue
        names = set(re.findall(r"{([^}]+)}", path))
        if not names:
            continue
        declared = set()

        def collect(params):
            for param in params or []:
                if isinstance(param, dict) and param.get("in") == "path" and "name" in param:
                    declared.add(param["name"])

        collect(item.get("parameters"))
        for method, operation in item.items():
            if method in HTTP_METHODS and isinstance(operation, dict):
                collect(operation.get("parameters"))

        missing = names - declared
        if missing:
            params = item.setdefault("parameters", [])
            for name in sorted(missing):
                params.append(
                    {"name": name, "in": "path", "required": True, "schema": {"type": "string"}}
                )


def declare_recording_download_body(doc):
    """Declare the binary response body for the recording-download endpoint.

    The published spec documents `GET /api/Recordings/{recordingKey}/file/{qualityName}`
    with an empty 200, so the generator discards the file bytes. Declare an
    `application/octet-stream` binary body so the generated client exposes the download.
    """
    path = "/api/Recordings/{recordingKey}/file/{qualityName}"
    item = (doc.get("paths") or {}).get(path)
    if not isinstance(item, dict):
        return
    operation = item.get("get")
    if not isinstance(operation, dict):
        return
    responses = operation.setdefault("responses", {})
    ok = responses.get("200")
    if not isinstance(ok, dict):
        ok = {"description": "OK"}
        responses["200"] = ok
    if not ok.get("content"):
        ok["content"] = {
            "application/octet-stream": {"schema": {"type": "string", "format": "binary"}}
        }


def require_multipart_bodies(doc):
    """Mark multipart request bodies as required.

    swift-openapi-generator only generates multipart request bodies when they are required;
    optional ones are silently skipped. Uploads (avatars, kiosk artwork) send a body, so
    make those bodies required to keep the operation usable.
    """
    for item in (doc.get("paths") or {}).values():
        if not isinstance(item, dict):
            continue
        for method, operation in item.items():
            if method not in HTTP_METHODS or not isinstance(operation, dict):
                continue
            body = operation.get("requestBody")
            if isinstance(body, dict) and "multipart/form-data" in (body.get("content") or {}):
                body["required"] = True


src, dst = sys.argv[1], sys.argv[2]
with open(src, encoding="utf-8") as f:
    doc = json.load(f)

info = doc.setdefault("info", {})
info.setdefault("version", "1.0.0")
normalize_int_bounds(doc)
relax_additional_properties(doc)
strip_deprecated(doc)
ensure_path_parameters(doc)
require_multipart_bodies(doc)
declare_recording_download_body(doc)

with open(dst, "w", encoding="utf-8") as f:
    json.dump(doc, f, ensure_ascii=False, indent=2, sort_keys=True)
    f.write("\n")
PY

echo "Wrote $OUT ($(wc -c <"$OUT" | tr -d ' ') bytes)"
