# paper-workspace ルール

論文執筆の共通基盤。**常にこの paper-workspace ルートで起動**し、各論文は `papers/<name>/`（独立した非公開リポ）をサブディレクトリとして編集する。

## 執筆支援スキル

`skills/` が正本。`.agents/skills/` と `.claude/skills/` はそこへの symlink で、Codex は `.agents/skills/`、Claude Code は `.claude/skills/` から同じ実体を読む。

- 文章作法: `research-paper-writing` / `paragraph-writing`
- 日本語表記校正: `japanese-paper-proofreading`
- 体裁（2カラム図表）: `latex-typesetting`
- ビルド環境: `latex-build`
- Overleaf 同期: `overleaf-sync`

スキルを追加・改名したら `bash scripts/link-skills.sh` を再実行して両ディレクトリを揃える。

## LaTeX 自動ビルド

ターン終了（Stop）時に `scripts/build-changed-papers.sh` が走り、`papers/*/` のうち `.tex`/`.bib` に変更があった論文だけを Docker でビルドする。状態（ハッシュ・ロック）は `.cache/` に置き、`papers/<name>/` には書かない（Overleaf 無汚染）。

手動ビルドは各論文で `./scripts/build-latex.sh`（`clean` / `version` も可）。

## 重要: papers/ を汚さない

`papers/<name>/` は Overleaf へ同期される。`.claude` / `.agents` / `.codex` や symlink、ビルド状態ファイルを `papers/<name>/` に置かない。エージェント基盤はすべて workspace ルートに集約する。

## Git 操作

- commit / push はユーザーから明示的に指示された場合のみ実行する。
- ファイル編集後に自動で commit / push しない。
