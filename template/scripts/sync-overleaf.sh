#!/usr/bin/env bash
# Overleaf と GitHub を同期するヘルパー。
#   1) Overleaf 上のメンバー編集を取り込む
#   2) GitHub へ反映
#   3) Overleaf へ反映
#
# 前提:
#   git remote add overleaf https://git@git.overleaf.com/<PROJECT_ID>
# 済みであること。Overleaf は単一ブランチのみ対応のため、両者とも同じブランチ名を使う。
#
# 環境変数で remote / branch を上書きできる:
#   GIT_REMOTE      GitHub の remote 名（既定: origin）
#   OVERLEAF_REMOTE Overleaf の remote 名（既定: overleaf）
#   GIT_BRANCH      対象ブランチ（既定: main）
set -euo pipefail

git_remote="${GIT_REMOTE:-origin}"
overleaf_remote="${OVERLEAF_REMOTE:-overleaf}"
branch="${GIT_BRANCH:-main}"

if ! git remote get-url "${overleaf_remote}" >/dev/null 2>&1; then
  echo "エラー: Overleaf remote '${overleaf_remote}' が未設定です。" >&2
  echo "  git remote add ${overleaf_remote} https://git@git.overleaf.com/<PROJECT_ID>" >&2
  exit 1
fi

if ! git remote get-url "${git_remote}" >/dev/null 2>&1; then
  echo "エラー: GitHub remote '${git_remote}' が未設定です。" >&2
  exit 1
fi

echo ">> Overleaf(${branch}) の変更を取り込み..."
git pull --no-rebase "${overleaf_remote}" "${branch}"

# Overleaf は実行権限を剥ぎ取るため pull 後に必ず復元する
git update-index --chmod=+x scripts/build-latex.sh scripts/sync-overleaf.sh 2>/dev/null || true
chmod +x scripts/build-latex.sh scripts/sync-overleaf.sh

echo ">> GitHub(${git_remote}/${branch}) へ push..."
git push "${git_remote}" "${branch}"

echo ">> Overleaf(${overleaf_remote}/${branch}) へ push..."
git push "${overleaf_remote}" "${branch}:${branch}"

echo ">> 同期完了。"
