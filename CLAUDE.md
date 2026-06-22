# paper-workspace ルール

論文執筆の共通基盤。複数論文を扱う場合は paper-workspace ルートで起動し、各論文は `papers/<name>/`（独立した非公開リポ）をサブディレクトリとして編集する。論文リポジトリを単独で起動する運用も可能。

## 執筆支援スキル

スキルの正本は `template/.agents/skills/`。`template/.claude/skills/` と各 `papers/<name>/{.agents,.claude}/skills/` には通常ファイルとして複製する。

- 文章作法: `research-paper-writing` / `paragraph-writing`
- 日本語表記校正: `japanese-paper-proofreading`
- 体裁（2カラム図表）: `latex-typesetting`
- ビルド環境: `latex-build`
- Overleaf 同期: `overleaf-sync`

スキルを追加・改名したら `bash scripts/sync-paper-skills.sh` を実行してテンプレートと既存論文を揃える。workspaceルートの `.claude` / `.codex` はフックのみを保持し、スキルは置かない。

## LaTeX 自動ビルド

workspace ルート起動時は、ターン終了（Stop）に `scripts/build-changed-papers.sh` が走り、`papers/*/` のうちソースに変更があった論文だけを Docker でビルドする。状態（ハッシュ・ロック）は workspace の `.cache/` に置く。

論文リポジトリ単独起動時は、そのリポジトリの `.claude` / `.codex` フックが `./scripts/build-latex-if-changed.sh` を呼ぶ。手動ビルドは各論文で `./scripts/build-latex.sh`（`clean` / `version` も可）。

## papers/ 内のエージェント設定

各論文リポジトリは `.claude` / `.agents` / `.codex` を通常ファイルとして Git 管理し、Overleaf にも同期してよい。シンボリックリンクは置かず、実行状態は Git 管理外の `.cache/` に保存する。

## Git 操作

- commit / push はユーザーから明示的に指示された場合のみ実行する。
- ファイル編集後に自動で commit / push しない。
