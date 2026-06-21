#!/usr/bin/env bash
# skills/ を正本として、Claude Code(.claude/skills/) と Codex(.agents/skills/) の
# スキル探索先に、各スキルへの相対 symlink を（再）生成する。
#
# paper-workspace ルートから常に agent を起動する前提:
#   - Claude Code は project の .claude/skills/ を読む
#   - Codex は .agents/skills/ を読む（.claude/skills/ は読まない）
# どちらも skills/<name> への symlink を辿って同じ実体を参照する。
#
# 冪等。skills を追加・改名・削除したら再実行すれば両ディレクトリが揃う。
# paper-workspace は Overleaf へ同期しないため symlink を安全に使える
# （Overleaf へ push される papers/<name>/ には symlink を一切置かない）。
set -euo pipefail

ws_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ws_root}"

src_dir="skills"
targets=(".claude/skills" ".agents/skills")

if [[ ! -d "${src_dir}" ]]; then
  echo "エラー: ${src_dir}/ が見つかりません（paper-workspace ルートで実行してください）。" >&2
  exit 1
fi

for t in "${targets[@]}"; do
  mkdir -p "${t}"
  # 管理対象（このスクリプトが張った symlink）を一旦掃除する。
  # 実体ディレクトリ（手動で置いた project skill 等）はそのまま残す。
  find "${t}" -maxdepth 1 -type l -exec rm -f {} +
done

linked=0
for skill_path in "${src_dir}"/*/; do
  [[ -f "${skill_path}SKILL.md" ]] || continue
  name="$(basename "${skill_path}")"
  for t in "${targets[@]}"; do
    ln -s "../../${src_dir}/${name}" "${t}/${name}"
  done
  linked=$((linked + 1))
done

echo ">> ${linked} スキルを .claude/skills/ と .agents/skills/ にリンクしました。"
echo "   （Claude Code を新規ディレクトリ作成後に再起動するとスキルが認識されます）"
