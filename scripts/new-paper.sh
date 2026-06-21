#!/usr/bin/env bash
# template/ から新しい論文ディレクトリを papers/<name>/ に作成し、git リポジトリとして初期化する。
#
# 使い方:
#   ./scripts/new-paper.sh <paper-name>
#
# 学会指定のテンプレートを使う場合は、このスクリプトの代わりに、その学会の
# .tex 一式を papers/<name>/ に置き、template/scripts/ と template/latexmkrc を
# コピーすればローカルビルド・Overleaf 同期の仕組みだけ流用できる。
set -euo pipefail

ws_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_dir="${ws_root}/template"

name="${1:-}"
if [[ -z "${name}" ]]; then
  echo "使い方: ./scripts/new-paper.sh <paper-name>" >&2
  exit 2
fi

dest="${ws_root}/papers/${name}"
if [[ -e "${dest}" ]]; then
  echo "エラー: ${dest} は既に存在します。" >&2
  exit 1
fi

if [[ ! -d "${template_dir}" ]]; then
  echo "エラー: template ディレクトリが見つかりません: ${template_dir}" >&2
  exit 1
fi

echo ">> ${dest} に template をコピー..."
mkdir -p "${dest}"
# 隠しファイル（.gitignore / .claude / .codex）も含めてコピー
cp -R "${template_dir}/." "${dest}/"

chmod +x "${dest}/scripts/build-latex.sh" "${dest}/scripts/sync-overleaf.sh" 2>/dev/null || true
chmod +x "${dest}/.codex/hooks/"*.sh 2>/dev/null || true

echo ">> git リポジトリを初期化..."
git -C "${dest}" init -q
git -C "${dest}" add -A
git -C "${dest}" commit -q -m "chore: ${name} を template から初期化"

cat <<NEXT

完了: papers/${name}/ を作成しました。

次の手順:
  1) 論文の非公開リポジトリを作成して push（例: GitHub）:
       cd papers/${name}
       gh repo create <owner>/${name} --private --source . --remote origin --push
  2) Overleaf と同期する場合（docs/overleaf-sync.md 参照）:
       git remote add overleaf https://git@git.overleaf.com/<PROJECT_ID>
       git config remote.overleaf.push refs/heads/main:refs/heads/main
       ./scripts/sync-overleaf.sh
  3) ローカルビルド:
       cd papers/${name} && ./scripts/build-latex.sh

注: papers/ はワークスペースの .gitignore で追跡対象外です。各論文は独立した（非公開）リポジトリとして管理されます。
NEXT
