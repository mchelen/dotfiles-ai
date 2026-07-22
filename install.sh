#!/usr/bin/env bash
# Assemble defaults/*.md into a single block and install it into the
# user-level instruction files of supported AI coding tools.
#
# Idempotent: content lives between BEGIN/END markers, so re-running
# replaces the managed block and leaves anything else in the file alone.
#
# A target is only written if its tool's config directory already exists
# (i.e. the tool appears to be installed), so you don't accumulate files
# for tools you don't use.
#
# Usage:
#   ./install.sh            install/update the managed block for detected tools
#   ./install.sh --all      install for every known tool, detected or not
#   ./install.sh --print    print the assembled block to stdout and exit

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BEGIN_MARK="<!-- BEGIN dotfiles-ai (managed block, edit in the dotfiles-ai repo) -->"
END_MARK="<!-- END dotfiles-ai -->"

# User-level instruction files of tools that read markdown guidance.
# Add or remove entries to match the tools you use.
TARGETS=(
  "$HOME/.claude/CLAUDE.md"                 # Claude Code (CLI/desktop/IDE)
  "$HOME/.codex/AGENTS.md"                  # OpenAI Codex CLI
  "$HOME/.copilot/copilot-instructions.md"  # GitHub Copilot CLI
  "$HOME/.gemini/GEMINI.md"                 # Google Gemini CLI
  "$HOME/.qwen/QWEN.md"                     # Qwen Code
  "$HOME/.config/opencode/AGENTS.md"        # OpenCode
  "$HOME/.config/goose/.goosehints"         # Goose
)

assemble() {
  echo "$BEGIN_MARK"
  for f in "$REPO_DIR"/defaults/*.md; do
    cat "$f"
    echo
  done
  echo "$END_MARK"
}

install_all=0
case "${1:-}" in
  --print) assemble; exit 0 ;;
  --all)   install_all=1 ;;
  "")      ;;
  *)       echo "unknown option: $1" >&2; exit 2 ;;
esac

block="$(assemble)"

for target in "${TARGETS[@]}"; do
  dir="$(dirname "$target")"

  if [[ ! -d "$dir" && "$install_all" -eq 0 ]]; then
    echo "skipped  $target (no $dir — tool not detected; use --all to force)"
    continue
  fi

  mkdir -p "$dir"
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
