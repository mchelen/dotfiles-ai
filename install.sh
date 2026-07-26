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
#   ./install.sh --brief    print the condensed one-line-per-module block and exit

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

# Modules are flat files in defaults/; categories are a documentation
# concept (see the README), not a directory layout.
assemble() {
  local found=0
  echo "$BEGIN_MARK"
  for f in "$REPO_DIR"/defaults/*.md; do
    [[ -f "$f" ]] || continue
    found=1
    cat "$f"
    echo
  done
  echo "$END_MARK"
  [[ $found -eq 1 ]] || { echo "no modules found in $REPO_DIR/defaults/" >&2; return 1; }
}

# Condensed form: the H1 and the bold thesis sentence from each module, one
# line each, with no BEGIN/END markers: those exist so the full block can be
# replaced in place inside a file, and a settings textarea has nothing to match
# against, so they would be ~100 characters of pure cost against a hard cap.
# Exists because the persistent-instruction fields in web chat
# products cap out well below the size of the full block (see the website's
# "Web chat" install path). Every module must carry a thesis sentence — a
# paragraph wrapped in ** ** directly under its heading — and assembly fails
# loudly rather than silently dropping a module that lacks one.
brief() {
  local found=0
  echo "My working defaults (dotfiles-ai). Follow these unless I say otherwise."
  echo
  for f in "$REPO_DIR"/defaults/*.md; do
    [[ -f "$f" ]] || continue
    found=1
    local line
    line="$(awk '
      /^\*\*/ && !done {
        buf = $0
        while (buf !~ /\*\*[[:space:]]*$/) { if ((getline nxt) <= 0) break; buf = buf " " nxt }
        sub(/^\*\*/, "", buf); sub(/\*\*[[:space:]]*$/, "", buf)
        print buf; done = 1
      }' "$f")"
    if [[ -z "$line" ]]; then
      echo "no thesis sentence (a **bold** paragraph under the heading) in $f" >&2
      return 1
    fi
    echo "- $line"
  done
  [[ $found -eq 1 ]] || { echo "no modules found in $REPO_DIR/defaults/" >&2; return 1; }
}

install_all=0
case "${1:-}" in
  --print) assemble; exit 0 ;;
  --brief) brief; exit 0 ;;
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
For web chat instruction fields, which are size-capped, use the condensed
form instead:                                     ./install.sh --brief
EOF
