#!/usr/bin/env bash
# Enforces "one API operation = one CLI command" (see AGENTS.md).
#
# Maps every operation the generator emitted into the client to the facade method that calls
# it and the CLI commands that reach it, and fails unless: one facade method calls each
# operation, each operation has exactly one command, each command reaches exactly one
# operation, and every command is registered in its group and the group in `ktalk`.
# Reads the generated Client.swift, so run it after `swift build`. Read-only; exits 1 and
# lists every gap on failure.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# The KTalkSDK plugin output only: .build also holds example clients from package checkouts.
CLIENT="$(find "$REPO_ROOT/.build" -path '*/KTalkSDK/*/GeneratedSources/Client.swift' -exec ls -t {} + 2>/dev/null | head -1)"
if [[ -z "$CLIENT" ]]; then
  echo "check-cli-coverage: no generated Client.swift under .build — run 'swift build' first" >&2
  exit 1
fi

python3 - "$CLIENT" "$REPO_ROOT" <<'PY'
import pathlib
import re
import sys

client, root = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])


def code(path):
    """A Swift file's text with `//` comments removed, so doc references are not calls."""
    return re.sub(r"//[^\n]*", "", path.read_text(encoding="utf-8"))


def blocks(text, header, end=r"^\S"):
    """Yields (name, body) for each `header` match. A body stops at the next header or at the
    next line matching `end` (by default any line at column 0, e.g. a closing brace)."""
    for match in re.finditer(header, text, re.M):
        start = text.find("\n", match.end()) + 1 or len(text)  # search from the next line
        stop = re.compile(rf"{header}|{end}", re.M).search(text, start)
        yield match.group(1), text[match.start():stop.start() if stop else len(text)]


operations = {
    name: route
    for route, name in re.findall(
        r"/// - Remark: HTTP `([A-Z]+ [^`]+)`\.\n\s*/// - Remark: Generated from[^\n]*\n"
        r"\s*public func (\w+)\(",
        client.read_text(encoding="utf-8"),
    )
}

problems = []

# Facade: what each public method calls, directly and through other facade methods.
direct, calls = {}, {}
for path in sorted((root / "Sources/KTalkSDK").glob("KTalkClient*.swift")):
    for name, body in blocks(code(path), r"^  public func (\w+)", end=r"^\S|^  \}"):
        if name in direct:
            problems.append(f"facade method {name} is overloaded; give each overload its own name")
        direct.setdefault(name, set()).update(
            op for op in re.findall(r"\bclient\.(\w+)\(", body) if op in operations)
        calls.setdefault(name, set()).update(
            m for m in re.findall(r"\b(\w+)\(", body) if m != name)
facade = {name: set(ops) for name, ops in direct.items()}
changed = True
while changed:  # close over facade-to-facade calls at any depth
    changed = False
    for name in facade:
        reach = set().union(*(facade[m] for m in calls[name] if m in facade))
        if not reach <= facade[name]:
            facade[name] |= reach
            changed = True

# One facade method calls each operation; wrappers (e.g. fetch-all) build on that method.
callers = {}
for name, ops in direct.items():
    for op in ops:
        callers.setdefault(op, []).append(name)
for op, names in sorted(callers.items()):
    if len(names) > 1:
        problems.append(f"{operations[op]} is called by several facade methods: {', '.join(names)}")

# CLI: every command (a struct with run()) inside each group's extension.
root_text = code(root / "Sources/ktalk/KTalk.swift")
root_groups = re.search(r"subcommands: \[(.*?)\]", root_text, re.S).group(1)
commands = {}
for path in sorted((root / "Sources/ktalk").rglob("*.swift")):
    text = code(path)
    for group, group_body in blocks(text, r"^extension (\w+) \{", end=r"^\}"):
        declaration = re.search(rf"^struct {group}: AsyncParsableCommand.*?^\}}", text, re.M | re.S)
        listed = re.search(r"subcommands: \[(.*?)\]", declaration.group(0), re.S) if declaration else None
        for name, body in blocks(group_body, r"^  struct (\w+): AsyncParsableCommand", end=r"^\}|^  \}"):
            if "func run()" not in body:
                continue
            label = f"{path.relative_to(root)}:{group}.{name}"
            if not (listed and re.search(rf"\b{name}\.self\b", listed.group(1))
                    and re.search(rf"\b{group}\.self\b", root_groups)):
                problems.append(f"command {label} is not registered in its group or the group in ktalk")
            commands[label] = {
                op for method in re.findall(r"\.(\w+)\(", body) if method in facade
                for op in facade[method]
            }

for label, ops in sorted(commands.items()):
    if len(ops) != 1:
        routes = ", ".join(sorted(operations[op] for op in ops)) or "none"
        problems.append(f"command {label} reaches {len(ops)} operations: {routes}")
owners = {}
for label, ops in commands.items():
    for op in ops:
        owners.setdefault(op, []).append(label)
for op, route in sorted(operations.items(), key=lambda item: item[1]):
    owned = owners.get(op, [])
    if len(owned) != 1:
        problems.append(f"{route} has {len(owned)} commands: {', '.join(owned) or 'none'}")

if problems:
    print(f"check-cli-coverage: {len(problems)} violations of one operation = one command")
    print("\n".join(f"  {p}" for p in problems))
    sys.exit(1)
print(f"check-cli-coverage: {len(operations)} operations, {len(commands)} commands, one to one")
PY
