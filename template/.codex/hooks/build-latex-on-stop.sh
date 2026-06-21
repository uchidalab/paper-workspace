#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
marker="${repo_root}/.codex/.tex-edited-since-stop"
lock_dir="${repo_root}/.codex/.latex-build.lock"

if [[ ! -f "${marker}" ]]; then
  exit 0
fi

if [[ ! -x "${repo_root}/scripts/build-latex.sh" ]]; then
  echo "LaTeX build skipped: scripts/build-latex.sh is missing or not executable." >&2
  exit 1
fi

if ! mkdir "${lock_dir}" 2>/dev/null; then
  echo "LaTeX build skipped: another hook build is already running." >&2
  exit 0
fi
trap 'rmdir "${lock_dir}" 2>/dev/null || true' EXIT

cd "${repo_root}"
./scripts/build-latex.sh
rm -f "${marker}"
