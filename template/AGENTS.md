# リポジトリルール

## LaTeX / PDF ビルド

- ローカルでの LaTeX ビルド確認を許可する。
- 標準のビルド手順は Docker 経由の `./scripts/build-latex.sh` とする。
- Overleaf 側の Compiler は `LaTeX`、ローカルの実行系は `latexmkrc` に従う `platex` / `pbibtex` / `dvipdfmx` とする。
- `.tex` や `.bib` などを編集した後、必要に応じて `./scripts/build-latex.sh` で `main.pdf` の生成を確認する。
- ビルドする主ファイルが `main.tex` でない場合は `LATEX_MAIN` で指定する。主ファイル名を `.latexmain` に書いておくと、ワークスペースの自動ビルドもそれを使う。
- Overleaf と厳密な差分確認が必要な場合は、Overleaf 側の TeX Live バージョンとビルドログも確認する。
- paper-workspace ルートから起動した場合は、workspace 側の Stop フックが変更された論文をビルドする。
- この論文リポジトリから単独起動した場合は、`.claude/settings.json` / `.codex/hooks.json` の Stop フックが `./scripts/build-latex-if-changed.sh` を呼び、この論文に変更がある場合だけビルドする。
- `.claude` / `.agents` / `.codex` はスキル実体を含めて Git 管理し、Overleaf にも同期する。シンボリックリンクは使用せず、フックの実行状態は `.cache/` に置いて Git 管理しない。

## 執筆支援スキル

- Claude Code は `.claude/skills/`、Codex は `.agents/skills/` に複製されたスキル実体を読む。
- この論文リポジトリだけをクローン・起動した場合も、グローバル登録なしで利用できる。

## Git 操作

- commit / push はユーザーから明示的に指示された場合のみ実行する。
- ファイル編集後に自動で commit / push しない。

## レビュー・添削対応の記録

- 概要・本文へのレビュー／添削の指摘に対応して `.tex` を修正したら、`docs/review-revisions/<日付>-<対象>.md` に「指摘・対応・根拠・確定文」を記録する（同じ指摘を繰り返さないため）。
- 記録には、判断の根拠（参照した考察ドキュメントや式・数値）と、一般化できる教訓（今後守るべき方針）を含める。
- 既存の記録は修正の出発点として先に確認する。
