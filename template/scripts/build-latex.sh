#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image="${LATEX_IMAGE:-texlive/texlive:TL2025-historic}"
platform="${LATEX_PLATFORM:-}"
main="${LATEX_MAIN:-main.tex}"

if [[ -z "${platform}" && "${image}" == "texlive/texlive:TL2025-historic" ]]; then
  platform="linux/amd64"
fi

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/build-latex.sh [build]
  ./scripts/build-latex.sh clean
  ./scripts/build-latex.sh version
  ./scripts/build-latex.sh shell

Environment:
  LATEX_IMAGE     Docker image to use. Default: texlive/texlive:TL2025-historic
  LATEX_PLATFORM  Docker platform to use. Default for TL2025-historic: linux/amd64
  LATEX_MAIN      Main .tex file to build. Default: main.tex
USAGE
}

docker_args=(
  --rm
  --user "$(id -u):$(id -g)"
  --env HOME=/tmp
  --volume "${repo_root}:/work"
  --workdir /work
)

if [[ -t 0 && -t 1 ]]; then
  docker_args=(-it "${docker_args[@]}")
fi

if [[ -n "${platform}" ]]; then
  docker_args=(--platform "${platform}" "${docker_args[@]}")
fi

run_texlive() {
  docker run "${docker_args[@]}" "${image}" "$@"
}

cmd="${1:-build}"
case "${cmd}" in
  build)
    run_texlive sh -c "latexmk -interaction=nonstopmode -halt-on-error -file-line-error '${main}'"
    ;;
  clean)
    run_texlive sh -c "latexmk -C '${main}'"
    ;;
  version)
    printf 'Docker image: %s\n' "${image}"
    printf 'Docker platform: %s\n' "${platform:-default}"
    printf 'Main file: %s\n' "${main}"
    run_texlive sh -c '
      platex --version | head -n 1
      pbibtex --version | head -n 1
      dvipdfmx --version | head -n 1
      latexmk -v | head -n 1
      tlmgr --version | grep "TeX Live" | head -n 1
    '
    ;;
  shell)
    run_texlive sh
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
