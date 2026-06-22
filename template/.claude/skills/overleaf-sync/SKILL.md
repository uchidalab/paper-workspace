---
name: overleaf-sync
description: "LaTeX 論文リポジトリを GitHub と Overleaf で双方向同期する運用手順。初回の overleaf remote 設定、sync-overleaf.sh による pull→push origin→push overleaf の流れ、単一ブランチ制約・実行権限の復元・fetch first 衝突・トークン認証の扱いを定める。MANDATORY TRIGGERS: Overleaf sync, Overleaf 同期, overleaf 同期, sync-overleaf, sync-overleaf.sh, git overleaf, Overleaf push, Overleaf pull, GitHub Overleaf 双方向同期, overleaf remote 設定."
---

# Overleaf / GitHub 同期

LaTeX 論文リポジトリを **GitHub（origin）** と **Overleaf** の両方に接続し、双方向に同期するための運用手順。GitHub を正本・履歴・レビューの場、Overleaf を共同編集・コンパイルの場として使う。

```
origin   -> GitHub                            … 正本・履歴・レビュー
overleaf -> git.overleaf.com/<PROJECT_ID>     … Overleaf エディタでの編集・コンパイル
```

## 大前提（確定ルール）

- **Overleaf は単一ブランチのみ**。両者とも同じブランチ（既定 `main`）を使い、push は `main:main`。
- **Overleaf はシンボリックリンク非対応**。Overleaf へ送る内容に symlink を含めない（含めるなら追跡対象外にする）。
- **Overleaf は push 時に実行権限（+x）を剥ぎ取る**。pull 後にスクリプトの `chmod +x` を復元する。
- **トークンはコミット・共有しない**。各自のアカウントで生成し、キーチェーン等に保存する。

## 初回セットアップ（各メンバーが1回）

1. Overleaf プロジェクトのコラボレーターに追加してもらう。
2. Overleaf → Account Settings → **Git Integration** でトークンを生成（= パスワード相当）。
3. remote を追加（`<PROJECT_ID>` は Overleaf プロジェクト ID）:
   ```bash
   git remote add overleaf https://git@git.overleaf.com/<PROJECT_ID>
   git config remote.overleaf.push refs/heads/main:refs/heads/main
   git config credential.helper osxkeychain   # macOS。初回認証後はトークン入力不要
   ```
4. 初回認証（username=`git`, password=トークン）:
   ```bash
   git ls-remote overleaf
   ```
   `refs/heads/main` が表示されれば成功（トークンはキーチェーンに保存される）。

## 日常運用

標準は同期ヘルパー `scripts/sync-overleaf.sh`。内部で次の3段を順に行う:

1. `git pull --no-rebase overleaf main` … Overleaf 上の編集を取り込む
2. スクリプトの `chmod +x` を復元（Overleaf が剥ぐため）
3. `git push origin main` → `git push overleaf main:main`

```bash
./scripts/sync-overleaf.sh
```

remote 名・ブランチ名は環境変数で上書きできる: `GIT_REMOTE`（既定 origin）/ `OVERLEAF_REMOTE`（既定 overleaf）/ `GIT_BRANCH`（既定 main）。手動なら:

```bash
git pull --no-rebase overleaf main   # 取り込み
git push origin main                  # GitHub へ
git push overleaf main:main           # Overleaf へ
```

## よくあるトラブル

- **push が `fetch first` / `non-fast-forward` で弾かれる**: Overleaf がアクセス時に自動で「Update on Overleaf」コミットを作ったため。`git pull --no-rebase overleaf main` してから再 push する（`sync-overleaf.sh` はこの順序）。
- **pull 後にスクリプトが実行できない**: Overleaf が +x を剥いだため。`chmod +x scripts/*.sh` で復元（`git update-index --chmod=+x ...` も併用すると追跡情報も直る）。
- **認証が通らない/毎回トークンを聞かれる**: credential helper 未設定。`git config credential.helper osxkeychain`（macOS）後に一度 `git ls-remote overleaf` で保存する。CI 等の非対話環境では `GIT_TERMINAL_PROMPT=0` を付け、保存済み資格情報で通す。
- **図やビルド成果物の扱い**: 図版 `figs/*.pdf` は追跡対象、ローカルビルド成果物（`*.pdf` / `*.aux` 等）は `.gitignore` 済みにする。

## ビルドとの関係

ローカルでの PDF 確認・Docker/latexmk 環境の設定は別スキル `latex-build` を使う。本スキルは GitHub↔Overleaf の同期運用に限定する。
