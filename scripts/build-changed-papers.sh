#!/usr/bin/env bash
# paper-workspace ルートの Stop フック（Claude Code / Codex）から呼ばれ、
# papers/*/ のうちソース（.tex/.bib/図/スタイル等）に変更があった paper だけを
# Docker で PDF ビルドする。
#
# 状態（ビルド済みハッシュ・ロック）は workspace 側の .cache/latex-hash/ に置き、
# papers/<name>/ には一切書かない（papers/ は Overleaf へ同期されるため無汚染を維持）。
#
# 主ファイルは既定 main.tex。paper 内に .latexmain があればその名前を使う。
#
# 使い方:
#   build-changed-papers.sh            変更された論文をビルド（Stop フックの既定）
#   build-changed-papers.sh --seed     ビルドせずに現在のハッシュだけ保存（初回ビルド回避）
#   build-changed-papers.sh --dry-run  ビルドせずに、ビルド対象になる論文名だけ表示
set -euo pipefail

mode="build"
case "${1:-}" in
  --seed)    mode="seed" ;;
  --dry-run) mode="dry-run" ;;
  "")        mode="build" ;;
  *) echo "不明な引数: ${1}（--seed / --dry-run のみ）" >&2; exit 2 ;;
esac

ws_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ws_root}"

papers_dir="papers"
state_dir=".cache/latex-hash"
mkdir -p "${state_dir}"

[[ -d "${papers_dir}" ]] || exit 0

built=()
failed=()
changed=()

for paper_path in "${papers_dir}"/*/; do
  name="$(basename "${paper_path}")"
  builder="${paper_path}scripts/build-latex.sh"
  [[ -f "${builder}" ]] || continue

  main="main.tex"
  if [[ -f "${paper_path}.latexmain" ]]; then
    main="$(tr -d '[:space:]' < "${paper_path}.latexmain")"
  fi
  # 主ファイルが無い paper はスキップ
  [[ -f "${paper_path}${main}" ]] || continue

  # ソース一式の集約ハッシュ。.tex/.bib に加え、図（figs/ などの画像）・スタイル
  # （.sty/.cls/.bst）・latexmkrc も対象にし、これらの変更でも自動ビルドを起動する。
  # ビルド生成物（ルート直下の出力 .pdf や .aux/.bbl 等）は対象外にして無限ループを防ぐ。
  # 図 PDF は figs/ 等のサブディレクトリに置く前提（ルート直下の *.pdf は出力扱いで除外）。
  # ファイル名の空白に耐えるよう find -print0 / xargs -0 を使い、ハッシュ行を sort して
  # 走査順に依存しない値にする。
  current="$(cd "${paper_path}" && \
    find . -type f \
      \( -name '*.tex' -o -name '*.bib' -o -name '*.sty' -o -name '*.cls' \
         -o -name '*.bst' -o -name 'latexmkrc' -o -name '.latexmkrc' \
         -o -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.gif' \
         -o -name '*.bmp' -o -name '*.tif' -o -name '*.tiff' \
         -o -name '*.eps' -o -name '*.ps' -o -name '*.svg' -o -name '*.pdf' \) \
      -not -path '*/.git/*' -not -path '*/tmp/*' -not -regex '\./[^/]*\.pdf' -print0 \
    | xargs -0 shasum 2>/dev/null | LC_ALL=C sort | shasum | awk '{print $1}')"

  hash_file="${state_dir}/${name}.hash"
  prev="$(cat "${hash_file}" 2>/dev/null || true)"
  [[ "${current}" == "${prev}" ]] && continue
  changed+=("${name}")

  # --seed: ビルドせずハッシュだけ保存
  if [[ "${mode}" == "seed" ]]; then
    echo "${current}" > "${hash_file}"
    continue
  fi
  # --dry-run: ビルドもハッシュ保存もしない
  [[ "${mode}" == "dry-run" ]] && continue

  # paper 単位ロック（多重ビルド防止）
  lock_dir="${state_dir}/${name}.lock"
  if ! mkdir "${lock_dir}" 2>/dev/null; then
    continue
  fi

  log="/tmp/latex-build-${name}.log"
  if ( cd "${paper_path}" && LATEX_MAIN="${main}" bash scripts/build-latex.sh ) > "${log}" 2>&1; then
    echo "${current}" > "${hash_file}"
    built+=("${name}")
  else
    failed+=("${name}")
  fi
  rmdir "${lock_dir}" 2>/dev/null || true
done

# --seed / --dry-run はここで結果を出して終了
if [[ "${mode}" == "seed" ]]; then
  echo ">> seed 完了: ${#changed[@]} 論文のハッシュを保存しました（${changed[*]:-なし}）。"
  exit 0
fi
if [[ "${mode}" == "dry-run" ]]; then
  echo ">> ビルド対象: ${changed[*]:-なし}"
  exit 0
fi

# Claude Code 向け systemMessage（JSON）。Codex でも余分な stdout は無害。
msg=""
if [[ ${#built[@]} -gt 0 ]]; then
  msg="✅ LaTeX build OK: ${built[*]}"
fi
if [[ ${#failed[@]} -gt 0 ]]; then
  [[ -n "${msg}" ]] && msg="${msg} / "
  msg="${msg}❌ build 失敗: ${failed[*]}（/tmp/latex-build-<name>.log 参照）"
fi
if [[ -n "${msg}" ]]; then
  printf '{"systemMessage":"%s"}\n' "${msg}"
fi
exit 0
