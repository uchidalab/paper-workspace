#!/usr/bin/env bash
# paper-workspace ルートの Stop フック（Claude Code / Codex）から呼ばれ、
# papers/*/ のうち .tex/.bib に変更があった paper だけを Docker で PDF ビルドする。
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

  # .tex/.bib の集約ハッシュ（生成物 .bbl 等は対象外なので再ビルドループにならない）
  current="$(cd "${paper_path}" && \
    find . -type f \( -name '*.tex' -o -name '*.bib' \) \
      -not -path '*/.git/*' -not -path '*/tmp/*' \
    | LC_ALL=C sort | xargs shasum 2>/dev/null | shasum | awk '{print $1}')"

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
