#!/usr/bin/env bash
# Keep this machine's installed defaults in sync with the repo.
#
# Pulls the latest main (fast-forward only) and re-runs install.sh so every
# detected tool picks up the current modules. Also points the repo's
# core.hooksPath at hooks/, so a plain `git pull` re-installs too.
#
# Usage:
#   ./sync.sh          sync now
#   ./sync.sh --auto   for shell startup: at most one attempt per day
#                      (override with DOTFILES_AI_SYNC_INTERVAL, seconds),
#                      silent when offline or already up to date

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-ai"
STAMP="$STATE_DIR/last-sync"
INTERVAL="${DOTFILES_AI_SYNC_INTERVAL:-86400}"

auto=0
case "${1:-}" in
  --auto) auto=1 ;;
  "")     ;;
  *)      echo "unknown option: $1" >&2; exit 2 ;;
esac

if [[ $auto -eq 1 && -f "$STAMP" ]]; then
  now=$(date +%s)
  last=$(stat -c %Y "$STAMP" 2>/dev/null || stat -f %m "$STAMP")
  (( now - last < INTERVAL )) && exit 0
fi

mkdir -p "$STATE_DIR"
touch "$STAMP"  # stamp the attempt, not the success: one try per interval

# Route manual `git pull`s through the versioned post-merge hook.
git -C "$REPO_DIR" config core.hooksPath hooks

before=$(git -C "$REPO_DIR" rev-parse HEAD)
if ! DOTFILES_AI_SYNC=1 git -C "$REPO_DIR" pull --ff-only --quiet origin main; then
  if [[ $auto -eq 1 ]]; then
    exit 0  # offline or diverged history; try again next interval
  fi
  echo "sync: git pull failed (offline, or local history has diverged)" >&2
  exit 1
fi
after=$(git -C "$REPO_DIR" rev-parse HEAD)
installed=$(cat "$STATE_DIR/installed-commit" 2>/dev/null || true)

if [[ $auto -eq 1 && "$after" == "$installed" ]]; then
  exit 0  # installed state already matches HEAD; stay quiet at shell startup
fi

if [[ "$before" != "$after" ]]; then
  echo "dotfiles-ai: updated ${before:0:7} -> ${after:0:7}"
fi
"$REPO_DIR/install.sh"
echo "$after" > "$STATE_DIR/installed-commit"
