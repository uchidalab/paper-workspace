# 新しい論文を始める

このワークスペースでは、各論文を `papers/<name>/` 配下の **独立した（非公開）git リポジトリ** として管理する。`papers/` はワークスペースの `.gitignore` で追跡対象外なので、論文の中身が公開リポジトリに入ることはない。

## 1. template から作る（推奨）

```bash
./scripts/new-paper.sh my-paper
```

これで `papers/my-paper/` に `template/` の内容（`main.tex`、`stylefile.sty`、`latexmkrc`、`scripts/`、`.claude/`、`.codex/`、`section/` 雛形 など）がコピーされ、git リポジトリとして初期化される。

その後の手順:

```bash
cd papers/my-paper
# 非公開リポジトリを作成して push
gh repo create <owner>/my-paper --private --source . --remote origin --push
# ローカルビルド
./scripts/build-latex.sh
```

Overleaf と同期する場合は `docs/overleaf-sync.md` を参照して `overleaf` remote を追加する。

## 2. 学会指定のテンプレートを使う

学会・ジャーナルが配布する LaTeX テンプレートを使う場合は、その一式を `papers/<name>/` に置き、ビルド・同期の仕組みだけを流用する:

```bash
mkdir -p papers/my-paper && cd papers/my-paper
# （学会テンプレートの .tex / .sty / .cls 一式をここに展開）
cp -R ../../template/scripts ./scripts
cp ../../template/latexmkrc ./latexmkrc
cp ../../template/.gitignore ./.gitignore
git init && git add -A && git commit -m "init from conference template"
```

主ファイルが `main.tex` でない場合は `LATEX_MAIN` で指定する:

```bash
LATEX_MAIN=paper.tex ./scripts/build-latex.sh
```

学会テンプレートが `pdflatex` / `uplatex` など別パイプラインを要求する場合は `latexmkrc` を合わせて調整する。

## 3. 執筆支援スキル

`skills/` の各スキルを `npx skills add` で登録すると、文章作法・日本語校正・体裁・ビルドの支援が使える。詳細はワークスペース直下の `README.md` を参照。
