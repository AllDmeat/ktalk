#!/usr/bin/env bash
# Enforces "one API operation = one CLI command" (see AGENTS.md).
#
# Maps every operation the generator emitted into the client to the CLI commands that reach
# it through the facade, and fails unless the mapping is one to one: each operation has
# exactly one command and each command reaches exactly one operation.
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


def blocks(text, header):
    """Yields (name, body) for each `header` match, body running to the next match."""
    starts = [(m.start(), m.group(1)) for m in re.finditer(header, text, re.M)]
    for index, (start, name) in enumerate(starts):
        end = starts[index + 1][0] if index + 1 < len(starts) else len(text)
        yield name, text[start:end]


operations = dict(
    (name, route)
    for route, name in re.findall(
        r"/// - Remark: HTTP `([A-Z]+ [^`]+)`\.\n\s*/// - Remark: Generated from[^\n]*\n"
        r"\s*public func (\w+)\(",
        client.read_text(encoding="utf-8"),
    )
)

# Facade method -> generated operations it reaches, directly or through another facade method.
# Methods are matched by name, so an overloaded name would make the mapping ambiguous.
direct, calls, overloaded = {}, {}, set()
for path in sorted((root / "Sources/KTalkSDK").glob("KTalkClient*.swift")):
    for name, body in blocks(code(path), r"^  public func (\w+)"):
        if name in direct:
            overloaded.add(name)
        direct.setdefault(name, set()).update(
            op for op in re.findall(r"\bclient\.(\w+)\(", body) if op in operations)
        calls.setdefault(name, set()).update(re.findall(r"\b(\w+)\(", body))
facade = {
    name: ops | {op for other in calls[name] if other in direct and other != name
                 for op in direct[other]}
    for name, ops in direct.items()
}

# CLI command -> operations it reaches. A command is a struct with a `run()`.
commands, unregistered = {}, []
root_groups = re.search(r"subcommands: \[(.*?)\]", code(root / "Sources/ktalk/KTalk.swift"), re.S)
for path in sorted((root / "Sources/ktalk").rglob("*.swift")):
    text = code(path)
    for group, group_body in blocks(text, r"^extension (\w+) \{"):
        for name, body in blocks(group_body, r"^  struct (\w+): AsyncParsableCommand"):
            if "func run()" not in body:
                continue
            label = f"{path.relative_to(root)}:{group}.{name}"
            registered = re.search(
                rf"^struct {group}: AsyncParsableCommand.*?subcommands: \[(.*?)\]", text, re.M | re.S)
            if (not registered or not re.search(rf"\b{name}\.self\b", registered.group(1))
                    or not re.search(rf"\b{group}\.self\b", root_groups.group(1))):
                unregistered.append(label)
            commands[label] = {
                op for method in re.findall(r"\.(\w+)\(", body) if method in facade
                for op in facade[method]
            }

problems = [f"facade method {name} is overloaded; give each overload its own name"
            for name in sorted(overloaded)]
problems += [f"command {label} is not registered in its group or the group in ktalk" for label in unregistered]
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
