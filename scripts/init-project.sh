#!/usr/bin/env bash
set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
  exit 0
fi

if ! ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  exit 0
fi

cd "$ROOT"

if command -v configure-grepai >/dev/null 2>&1; then
  configure-grepai
fi
