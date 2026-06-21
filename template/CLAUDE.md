# リポジトリルール

## LaTeX / PDF ビルド

- ローカルでの LaTeX ビルド確認を許可する。
- 標準のビルド手順は Docker 経由の `./scripts/build-latex.sh` とする。
- Overleaf 側の Compiler は `LaTeX`、ローカルの実行系は `latexmkrc` に従う `platex` / `pbibtex` / `dvipdfmx` とする。
- `.tex` や `.bib` などを編集した後、必要に応じて `./scripts/build-latex.sh` で PDF の生成を確認する。
- ビルドする主ファイルが `main.tex` でない場合は `LATEX_MAIN` で指定する（例: `LATEX_MAIN=paper.tex ./scripts/build-latex.sh`）。
- Overleaf と厳密な差分確認が必要な場合は、Overleaf 側の TeX Live バージョンとビルドログも確認する。

## Git 操作

- commit / push はユーザーから明示的に指示された場合のみ実行する。
- ファイル編集後に自動で commit / push しない。

## レビュー・添削対応の記録

- 概要・本文へのレビュー／添削の指摘に対応して `.tex` を修正したら、`docs/review-revisions/<日付>-<対象>.md` に「指摘・対応・根拠・確定文」を記録する（同じ指摘を繰り返さないため）。
- 記録には、判断の根拠（参照した考察ドキュメントや式・数値）と、一般化できる教訓（今後守るべき方針）を含める。
- 既存の記録は修正の出発点として先に確認する。

## 執筆支援スキル

このリポジトリはワークスペース（`paper-workspace`）の `skills/` で配布される論文執筆スキルの利用を想定する。`npx skills add` で登録したうえで、文章作法は `research-paper-writing` / `paragraph-writing`、日本語表記校正は `japanese-paper-proofreading`、体裁は `latex-typesetting`、ビルドは `latex-build` を使う。
