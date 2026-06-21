# Overleaf / GitHub 同期ガイド

各論文リポジトリは **GitHub** と **Overleaf** の両方に接続して運用する。

```
origin   -> GitHub                                   (ブランチ main) … メンバー + AI の正本・履歴・レビュー
overleaf -> git.overleaf.com/<PROJECT_ID>            (ブランチ main) … Overleaf エディタでの編集・コンパイル
```

Overleaf は単一ブランチのみ対応。両者とも同じブランチ名（既定 `main`）を使い、`main:main` で push する。

## 初回セットアップ（各メンバーが1回）

1. Overleaf プロジェクトのコラボレーターに追加してもらう（所有者が有料プランなら、各自は無料アカウントで git 利用可）。
2. Overleaf → Account Settings → **Git Integration** で **トークンを生成**する（トークン = パスワード相当。共有・コミットしない）。
3. リモートを追加（`<PROJECT_ID>` は Overleaf プロジェクトの ID に置き換える）:
   ```bash
   git remote add overleaf https://git@git.overleaf.com/<PROJECT_ID>
   git config remote.overleaf.push refs/heads/main:refs/heads/main
   git config credential.helper osxkeychain   # macOS。初回認証後はトークン入力不要
   ```
4. 初回認証（ターミナルで対話入力。username=`git`, password=トークン）:
   ```bash
   git ls-remote overleaf
   ```
   `refs/heads/main` が表示されれば成功（トークンはキーチェーンに保存される）。

## 日常運用

- **ローカル / AI で執筆**: `.tex` を編集 → commit → 下記ヘルパーで両方へ反映
  ```bash
  ./scripts/sync-overleaf.sh
  ```
  （個別にやるなら `git push origin main` と `git push overleaf main:main`）
- remote 名・ブランチ名を変える場合は環境変数で上書きできる: `GIT_REMOTE` / `OVERLEAF_REMOTE` / `GIT_BRANCH`。
- **メンバーの Overleaf 編集を取り込む**: `git pull --no-rebase overleaf main` → `git push origin main`
- メンバーは従来どおり **Overleaf エディタで編集・コンパイル**してよい。git を使わなくても、誰かが上記で取り込めば GitHub にも反映される。
- ブランチ運用が必要な作業は **GitHub 側（origin）** で行い、Overleaf へは `main` だけを流す。

## 注意

- トークンは各自のアカウントで生成し、**コミット・共有しない**（キーチェーン保存推奨）。
- Overleaf に push する内容で **シンボリックリンクは使わない**（Overleaf 非対応。`.claude/skills` の symlink は追跡対象外にしてある）。
- 図版 `figs/*.pdf` は追跡対象。ローカルビルド成果物（`*.pdf` / `*.aux` 等）は `.gitignore` 済み。
- Overleaf はアクセス時に自動で「Update on Overleaf」コミットを作ることがあり、push が `fetch first` で弾かれる場合がある。そのときは `git pull --no-rebase overleaf main` してから再 push する（`sync-overleaf.sh` はこの順序）。
- Overleaf は push 時にスクリプトの実行権限を剥ぎ取る。`sync-overleaf.sh` は pull 後に `chmod +x` を復元する。
