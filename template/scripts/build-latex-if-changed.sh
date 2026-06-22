#!/usr/bin/env bash
# 論文リポジトリ単独で Claude Code / Codex を起動した場合の Stop フック。
# LaTeX ソース・図・スタイルの内容が前回の成功ビルド時から変わった場合だけビルドする。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
state_dir="${repo_root}/.cache/latex-hook"
hash_file="${state_dir}/source.hash"
lock_dir="${state_dir}/build.lock"
main="${LATEX_MAIN:-}"

if [[ -z "${main}" && -f "${repo_root}/.latexmain" ]]; then
  main="$(head -n 1 "${repo_root}/.latexmain" | tr -d '\r')"
fi
main="${main:-main.tex}"

[[ -f "${repo_root}/${main}" ]] || exit 0

mkdir -p "${state_dir}"

current="$(
  cd "${repo_root}"
  find . -type f \
    \( -name '*.tex' -o -name '*.bib' -o -name '*.sty' -o -name '*.cls' \
       -o -name '*.bst' -o -name 'latexmkrc' -o -name '.latexmkrc' \
       -o -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.gif' \
       -o -name '*.bmp' -o -name '*.tif' -o -name '*.tiff' \
       -o -name '*.eps' -o -name '*.ps' -o -name '*.svg' -o -name '*.pdf' \) \
    -not -path '*/.git/*' -not -path '*/.cache/*' -not -path '*/tmp/*' \
    -not -regex '\./[^/]*\.pdf' -print0 \
  | xargs -0 shasum 2>/dev/null | LC_ALL=C sort | shasum | awk '{print $1}'
)"
previous="$(cat "${hash_file}" 2>/dev/null || true)"

[[ "${current}" != "${previous}" ]] || exit 0

if ! mkdir "${lock_dir}" 2>/dev/null; then
  echo "LaTeX build skipped: another hook build is already running." >&2
  exit 0
fi
trap 'rmdir "${lock_dir}" 2>/dev/null || true' EXIT

cd "${repo_root}"
LATEX_MAIN="${main}" ./scripts/build-latex.sh
printf '%s\n' "${current}" > "${hash_file}"
