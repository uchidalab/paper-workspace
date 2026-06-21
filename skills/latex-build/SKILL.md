---
name: latex-build
description: "LaTeX build environment setup and debugging, especially Docker-based latexmk workflows that mirror Overleaf compiler settings. MANDATORY TRIGGERS: LaTeX build, tex build, latexmk, platex, pbibtex, dvipdfmx, Overleaf compiler, Overleaf build, local PDF build, ローカルビルド, texビルド, LaTeX環境, Overleaf互換."
---

# LaTeX Build

## First Pass

Before changing files, inspect the project-local rules and build shape:

- Read `AGENTS.md` / `CLAUDE.md` when present.
- Read `latexmkrc`, `.latexmkrc`, Makefiles, Dockerfiles, CI config, and `.gitignore`.
- Identify the main document from repo docs, Overleaf docs, or root `main.tex`; do not guess if multiple plausible roots exist.
- Check existing generated files and dirty git state so user work is not mistaken for build output.

If repo rules prohibit local LaTeX builds, do not run `latexmk`, `pdflatex`, `platex`, or equivalent unless the user explicitly asks to change that policy.

## Overleaf Compatibility

Treat Overleaf compatibility as matching the important knobs, not byte-for-byte identity:

- Project settings: main document, Compiler, TeX Live version.
- Repo settings: `latexmkrc` / `.latexmkrc`, bibliography engine, image driver, shell escape, and source layout.
- Build logs: confirm actual commands such as `platex`, `pbibtex`, `dvipdfmx`, `pdflatex`, `xelatex`, `lualatex`, or `biber`.

Know the common mapping:

- Overleaf `Compiler: LaTeX` means a DVI-producing LaTeX workflow. With a repo `latexmkrc`, this can be `platex -> pbibtex -> dvipdfmx`.
- `pdfLaTeX` directly targets PDF and is usually wrong for Japanese pLaTeX projects using `jsarticle` plus `dvipdfmx`.
- Overleaf reads its own system-wide `LatexMk` before project `latexmkrc`, so local builds are practical compatibility unless the Overleaf `LatexMk` is explicitly copied and compared.

Use current official Overleaf docs when answering about available TeX Live versions, compiler settings, or Overleaf behavior.

## Standard Docker Setup

Prefer Docker for reproducible local builds unless the repo already has a stronger pattern.

For an Overleaf TeX Live 2025 pLaTeX project, use:

```bash
docker run --rm \
  --platform linux/amd64 \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --volume "$PWD:/work" \
  --workdir /work \
  texlive/texlive:TL2025-historic \
  sh -c 'latexmk -interaction=nonstopmode -halt-on-error -file-line-error main.tex'
```

Use `sh -c`, not `sh -lc`, when relying on TeX Live image `PATH`; login shells may reset `PATH` and hide TeX binaries.

Pin TeX Live by year or image tag for reproducibility. Avoid `latest` unless the user wants a moving target or is only doing a quick exploratory check.

## Implementation Pattern

When adding a reusable repo-local build command:

- Add a thin script such as `scripts/build-latex.sh` that mounts the repo, runs `latexmk`, supports `version` and `clean`, and accepts `LATEX_IMAGE` / `LATEX_PLATFORM`.
- Document the workflow in a short repo doc such as `docs/local-latex-build.md`.
- Update repo rules only when the user asks to allow local builds.
- Add missing generated artifacts to `.gitignore`, but do not ignore source PDFs under `figs/` or `docs/` unless the repo already treats them as generated.

Keep generated build files out of commits: `*.aux`, `*.bbl`, `*.blg`, `*.dvi`, `*.fdb_latexmk`, `*.fls`, `*.log`, root output PDFs such as `/main.pdf`, and similar intermediates.

## Verification

Run the smallest checks that prove the environment works:

```bash
./scripts/build-latex.sh version
./scripts/build-latex.sh
git status --short --ignored
```

Report:

- the TeX Live version and engines found;
- whether PDF generation succeeded;
- important LaTeX warnings only if they affect success or user intent;
- whether generated files are ignored;
- any existing unrelated dirty files that were left untouched.

Do not commit or push skill/build changes unless the user explicitly asks.
