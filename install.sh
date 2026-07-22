#!/usr/bin/env bash
# Assemble defaults/*.md into a single block and install it into the
# user-level instruction files of supported AI coding tools.
#
# Idempotent: content lives between BEGIN/END markers, so re-running
# replaces the managed block and leaves anything else in the file alone.
#
# Usage:
#   ./install.sh            install/update the managed block in all targets
#   ./install.sh --print    print the assembled block to stdout and exit

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BEGIN_MARK="<!-- BEGIN dotfiles-ai (managed block, edit in the dotfiles-ai repo) -->"
END_MARK="<!-- END dotfiles-ai -->"

# Tools that read user-level markdown instructions. Add or remove targets
# to match the tools you actually use.
TARGETS=(
  "$HOME/.claude/CLAUDE.md"   # Claude Code user memory
  "$HOME/.codex/AGENTS.md"    # OpenAI Codex CLI global guidance
)

assemble() {
  echo "$BEGIN_MARK"
  for f in "$REPO_DIR"/defaults/*.md; do
    cat "$f"
    echo
  done
  echo "$END_MARK"
}

if [[ "${1:-}" == "--print" ]]; then
  assemble
  exit 0
fi

block="$(assemble)"

for target in "${TARGETS[@]}"; do
  mkdir -p "$(dirname "$target")"
  touch "$target"

  if grep -qF "$BEGIN_MARK" "$target"; then
    cp "$target" "$target.bak"
    awk -v begin="$BEGIN_MARK" -v end="$END_MARK" '
      $0 == begin {skip=1; next}
      $0 == end   {skip=0; next}
      !skip {print}
    ' "$target.bak" > "$target"
    echo "updated  $target (previous version saved to $target.bak)"
  else
    echo "installed $target"
  fi

  # Ensure a blank line before the block, then append it.
  [[ -s "$target" ]] && echo >> "$target"
  printf '%s\n' "$block" >> "$target"
done

cat <<'EOF'

Done. For tools that only take rules through their settings UI
(e.g. Cursor "User Rules"), paste the output of:  ./install.sh --print
EOF
