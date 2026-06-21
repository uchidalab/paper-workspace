# paper-workspace

論文執筆の **共通基盤**（LaTeX ビルド環境・Overleaf 同期・執筆支援スキル・テンプレート）をまとめた公開ワークスペース。各論文は `papers/` 配下の独立した（非公開）リポジトリとして管理し、このワークスペース自体には論文の中身を含めない。

/ docs / にビルドと同期の詳しい手順、/ skills / に執筆支援スキル、/ template / に1論文ぶんの自己完結スケルトンが入っている。

**エージェントは常に paper-workspace ルートから起動する**（`papers/<name>/` はサブディレクトリとして編集する）。skills と保存時の自動ビルド hook はワークスペースルートに集約してあり、`papers/<name>/` 側には何も置かない（Overleaf へ同期されるため無汚染に保つ）。

## ディレクトリ構成

```
paper-workspace/                  ← ここから Claude / Codex を起動する
├── scripts/
│   ├── new-paper.sh              template から papers/<name>/ に新規論文を作成
│   ├── link-skills.sh            skills/ から .claude/skills・.agents/skills へ symlink を生成
│   └── build-changed-papers.sh   Stop フックが呼ぶ：変更された論文だけビルド
├── skills/                       論文執筆支援スキル（正本・このリポジトリで管理）
├── .claude/                      settings.json（Stop フック）+ skills/（skills/ への symlink）
├── .agents/skills/               Codex 用 skills/ への symlink
├── .codex/hooks.json             Codex 用 Stop フック
├── CLAUDE.md / AGENTS.md         ワークスペース運用ルール（Claude / Codex 共通内容）
├── template/                     1論文ぶんの自己完結スケルトン（LaTeX のみ）
│   ├── main.tex                  タイトル・著者はプレースホルダ
│   ├── stylefile.sty             既定フォーマット（2カラム jsarticle）
│   ├── latexmkrc                 platex / pbibtex / dvipdfmx
│   ├── scripts/                  build-latex.sh, sync-overleaf.sh
│   ├── section/                  章の雛形（abstract/intro/related/method/experiment/summ）
│   ├── figs/                     図の置き場
│   ├── bibsample.bib             参考文献データベースの雛形
│   └── CLAUDE.md / AGENTS.md     リポジトリルールの雛形
├── docs/                         ビルド・同期・新規作成の手順
└── papers/                       各論文（非公開リポ）を置く場所（.gitignore 済み）
```

## 必要なもの

- **Docker**（ローカル LaTeX ビルドに使用。TeX Live 2025 の image を pull する）
- **git** / **GitHub CLI (`gh`)**（リポジトリ作成・同期に使用）
- **Node.js / npx**（スキル登録に使用）

## 使い方

### 新しい論文を始める

```bash
./scripts/new-paper.sh my-paper
cd papers/my-paper
gh repo create <owner>/my-paper --private --source . --remote origin --push
./scripts/build-latex.sh
```

学会指定のテンプレートを使う場合を含め、詳細は [docs/new-paper.md](docs/new-paper.md) を参照。

### ローカルビルド

各論文ディレクトリで Docker 経由の pLaTeX ビルドを実行する。

```bash
./scripts/build-latex.sh          # main.tex をビルド
./scripts/build-latex.sh clean    # 生成物を削除
./scripts/build-latex.sh version  # TeX Live バージョン確認
```

主ファイルが `main.tex` 以外なら `LATEX_MAIN=paper.tex ./scripts/build-latex.sh`。詳細は [docs/local-latex-build.md](docs/local-latex-build.md)。

### Overleaf 同期

GitHub と Overleaf を双方向に同期する。

```bash
git remote add overleaf https://git@git.overleaf.com/<PROJECT_ID>
./scripts/sync-overleaf.sh
```

詳細は [docs/overleaf-sync.md](docs/overleaf-sync.md)。

## スキル

`skills/` に論文執筆を支援する [Agent Skills](https://github.com/anthropics/skills) を正本として置いている。`.claude/skills/`（Claude Code 用）と `.agents/skills/`（Codex 用）は `skills/<name>` への symlink で、**paper-workspace ルートから起動すれば両エージェントがそのまま参照できる**（global 登録は不要）。

スキルを追加・改名したら symlink を張り直す。

```bash
bash scripts/link-skills.sh
```

> workspace 外（別マシンや、各論文リポに `cd` して単独で開く場合）でも使いたいときは、任意でグローバル登録できる。
>
> ```bash
> npx --yes skills add ./skills/<skill-name> --global --yes
> ```

| スキル | 役割 |
|---|---|
| `latex-build` | Docker / latexmk ベースの LaTeX ビルド環境のセットアップとデバッグ |
| `overleaf-sync` | GitHub↔Overleaf の双方向同期（remote 設定・`sync-overleaf.sh` の運用） |
| `latex-typesetting` | 2カラム論文の図表配置・体裁規則 |
| `research-paper-writing` | ML/CV/NLP 系論文の構成・段落・推敲 |
| `paragraph-writing` | パラグラフ・ライティングと学術文章の作法 |
| `japanese-paper-proofreading` | 日本語論文の表記校正（句読点・全角半角・参照表記など） |

## papers/ の運用ルール

- `papers/` の中身はこの公開リポジトリでは追跡しない（`.gitignore` 済み）。
- 各論文は `papers/<name>/` に置いた **独立した非公開リポジトリ**として管理する。
- 共通基盤を更新したら、必要に応じて各論文へ反映する（`template/` が更新元）。
