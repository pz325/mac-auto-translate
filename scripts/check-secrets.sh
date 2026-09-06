#!/bin/sh
set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$PROJECT_ROOT"

PATTERN='(github[_]pat_[A-Za-z0-9_]{30,}|gh[pousr]_[A-Za-z0-9]{30,}|sk-[A-Za-z0-9_-]{24,}|sk-ant-[A-Za-z0-9_-]{20,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----)'

if rg -n --hidden \
    -g '!work/**' -g '!outputs/**' -g '!dist/**' -g '!.build/**' -g '!.git/**' \
    "$PATTERN" .; then
    echo "Potential secret found in working tree." >&2
    exit 1
fi

if git rev-parse --git-dir >/dev/null 2>&1; then
    if git log -p --all -- . ':!scripts/check-secrets.sh' 2>/dev/null | rg -n "$PATTERN"; then
        echo "Potential secret found in Git history." >&2
        exit 1
    fi
fi

echo "No known secret patterns found."
