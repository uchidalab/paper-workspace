#!/usr/bin/env bash
# template/.agents/skills/ を正本として、template/.claude/skills/ と既存の
# papers/*/{.agents,.claude}/skills/ にスキル実体を複製する。
#
# シンボリックリンクは使用しない。Overleaf に同期される各論文リポジトリが、
# 単独でクローンされた状態でも Claude Code / Codex の双方からスキルを読める。
set -euo pipefail

ws_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ws_root}"

src_dir="template/.agents/skills"

if [[ ! -d "${src_dir}" ]]; then
  echo "エラー: ${src_dir}/ が見つかりません。" >&2
  exit 1
fi

sync_to() {
  local target="$1"

  if [[ -L "${target}" ]]; then
    echo "エラー: 同期先がシンボリックリンクです: ${target}" >&2
    exit 1
  fi

  rm -rf "${target:?}"
  mkdir -p "${target}"

  for skill_path in "${src_dir}"/*/; do
    [[ -f "${skill_path}SKILL.md" ]] || continue
    name="$(basename "${skill_path}")"
    cp -R "${skill_path}" "${target}/${name}"
  done
}

sync_to "template/.claude/skills"

synced=0
for paper in papers/*/; do
  [[ -d "${paper}.git" ]] || continue
  sync_to "${paper}.agents/skills"
  sync_to "${paper}.claude/skills"
  synced=$((synced + 1))
done

echo ">> template と ${synced} 件の論文リポジトリへスキル実体を同期しました。"
