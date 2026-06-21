#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
marker="${repo_root}/.codex/.tex-edited-since-stop"

payload="$(cat || true)"

mentions_tex=false
if command -v jq >/dev/null 2>&1; then
  if printf '%s' "${payload}" | jq -e '.. | strings | select(test("(^|/)[^[:space:]]+\\.tex($|[^[:alnum:]_./-])"))' >/dev/null 2>&1; then
    mentions_tex=true
  fi
fi

if [[ "${mentions_tex}" != "true" ]] && printf '%s' "${payload}" | grep -Eq '(^|/)[^[:space:]]+\.tex($|[^[:alnum:]_./-])'; then
  mentions_tex=true
fi

if [[ "${mentions_tex}" == "true" ]]; then
  mkdir -p "$(dirname "${marker}")"
  date -u '+%Y-%m-%dT%H:%M:%SZ' > "${marker}"
fi
