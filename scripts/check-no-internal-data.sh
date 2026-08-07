#!/usr/bin/env bash
# Guards the public repo against leaked internal data.
#
# The only Kontur.Talk space that may appear anywhere in the repo is the placeholder
# `example.ktalk.ru`. Any other `<subdomain>.ktalk.ru` reference is treated as a real
# workspace name (or data captured from one) and fails the check. The published spec's
# `{space}.ktalk.ru` placeholder is not a subdomain match, so it is allowed. This script
# intentionally hard-codes no real names.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

ALLOWED="example"

matches="$(
    git grep -InE '[a-z0-9-]+\.ktalk\.ru' -- . ':(exclude)scripts/check-no-internal-data.sh' \
        | grep -vE "\b${ALLOWED}\.ktalk\.ru" || true
)"

if [ -n "$matches" ]; then
    echo "error: found non-placeholder *.ktalk.ru references (use ${ALLOWED}.ktalk.ru):" >&2
    echo "$matches" >&2
    exit 1
fi

echo "no-internal-data: clean (only ${ALLOWED}.ktalk.ru is referenced)"
