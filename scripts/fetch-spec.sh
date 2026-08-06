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


def strip_deprecated(node):
    """Remove OpenAPI `deprecated` flags document-wide.

    The generator marks deprecated members with `@available(*, deprecated)` and then
    references them in its own generated coding code, which trips `-warnings-as-errors`.
    Deprecation is advisory metadata; dropping it keeps the strict build clean without
    changing the wire behaviour of the client. Only boolean-valued `deprecated` keys (the
    OpenAPI flag) are removed, never a schema property that happens to be named `deprecated`.
    """
    if isinstance(node, dict):
        if isinstance(node.get("deprecated"), bool):
            del node["deprecated"]
        for child in node.values():
            strip_deprecated(child)
    elif isinstance(node, list):
        for child in node:
            strip_deprecated(child)


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
strip_deprecated(doc)
ensure_path_parameters(doc)
require_multipart_bodies(doc)

with open(dst, "w", encoding="utf-8") as f:
    json.dump(doc, f, ensure_ascii=False, indent=2, sort_keys=True)
    f.write("\n")
PY

echo "Wrote $OUT ($(wc -c <"$OUT" | tr -d ' ') bytes)"
