# ローカル LaTeX ビルド

各論文は Overleaf と同じ pLaTeX 系のビルドを Docker 上で再現する。`template/` から作った論文ディレクトリ（`papers/<name>/`）の中で実行する。

## 前提

- Docker が起動していること。
- Overleaf 側の Compiler は `LaTeX` にする。
- Overleaf 側の TeX Live は `2025` にする。
- main document は `main.tex` とする（別名のときは `LATEX_MAIN` で指定）。

ローカルでは `latexmkrc` に従い、`platex`、`pbibtex`、`dvipdfmx` を使う。

## 使い方

```bash
./scripts/build-latex.sh
```

初回は Docker image の pull に時間がかかる。生成される PDF と LaTeX の中間ファイルは `.gitignore` で除外する。

使用する TeX Live image を確認する。

```bash
./scripts/build-latex.sh version
```

生成物を削除する。

```bash
./scripts/build-latex.sh clean
```

主ファイルが `main.tex` でない場合は `LATEX_MAIN` を指定する。

```bash
LATEX_MAIN=paper.tex ./scripts/build-latex.sh
```

別の TeX Live image を試す場合は `LATEX_IMAGE` を指定する。

```bash
LATEX_IMAGE=texlive/texlive:latest ./scripts/build-latex.sh
```

Docker platform を変える場合は `LATEX_PLATFORM` を指定する。既定の `texlive/texlive:TL2025-historic` は amd64 image のため、スクリプトは標準で `linux/amd64` を使う。

```bash
LATEX_IMAGE=texlive/texlive:latest LATEX_PLATFORM=linux/arm64 ./scripts/build-latex.sh
```

## Overleaf との違い

Overleaf はプロジェクト側の `latexmkrc` に加えて、Overleaf 側の system-wide `LatexMk` を先に読み込む。したがって、このローカル環境は完全なバイト一致ではなく、TeX Live 年版と pLaTeX 系パイプラインを合わせる実用互換環境として扱う。

厳密な差分確認が必要な場合は、Overleaf の build log で `platex`、`pbibtex`、`dvipdfmx` が使われていることと、TeX Live バージョンを確認する。
