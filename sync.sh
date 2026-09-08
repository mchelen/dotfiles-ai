#!/usr/bin/env bash
# Keep this machine's installed defaults in sync with the repo.
#
# Pulls the latest main (fast-forward only) and re-runs install.sh so every
# detected tool picks up the current modules. Also installs the pre-commit
# framework's hooks, so commits are secret-scanned and a plain `git pull`
# re-installs too.
#
# Usage:
#   ./sync.sh          sync now
#   ./sync.sh --auto   for shell startup: at most one attempt per day
#
# If a remote named `upstream` exists, it also reports when your fork has
# fallen behind it. Merging that is your call, not this script's:
#   git remote add upstream https://github.com/mchelen/dotfiles-ai
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

# Set up the standard pre-commit framework hooks (secret scanning on
# commit, re-install after manual pulls). Migrates away from the old
# core.hooksPath approach if present.
git -C "$REPO_DIR" config --unset-all core.hooksPath 2>/dev/null || true
if command -v pre-commit >/dev/null 2>&1; then
  (cd "$REPO_DIR" && pre-commit install --hook-type pre-commit --hook-type post-merge >/dev/null 2>&1) || true
fi

before=$(git -C "$REPO_DIR" rev-parse HEAD)

# --quiet silences progress, not failures. An unreachable remote still prints
# five lines of git's own diagnostics, and in --auto that lands at the prompt
# on every shell start for as long as the laptop is offline — which is the one
# thing automatic mode must never do. Auto discards it and goes on the exit
# status; manual mode keeps it, where it is the useful part of the answer.
pull() { DOTFILES_AI_SYNC=1 git -C "$REPO_DIR" pull --ff-only --quiet origin main; }
if [[ $auto -eq 1 ]]; then
  pull >/dev/null 2>&1 || exit 0  # offline or diverged; try again next interval
elif ! pull; then
  echo "sync: git pull failed (offline, or local history has diverged)" >&2
  exit 1
fi
after=$(git -C "$REPO_DIR" rev-parse HEAD)

# Fork <- upstream stays a deliberate manual step: the fork is yours, and
# upstream changing underneath you is the thing forking avoids. But nobody
# clicks a button they don't know is waiting. If an `upstream` remote exists,
# say when it has moved ahead, and leave the decision alone.
#
# This runs before the "nothing to install" early exit below, because an idle
# machine — the fork unchanged, everything installed — is exactly the case
# where upstream is the only thing that has moved.
if git -C "$REPO_DIR" remote get-url upstream >/dev/null 2>&1 &&
   git -C "$REPO_DIR" fetch --quiet upstream main >/dev/null 2>&1; then
  behind=$(git -C "$REPO_DIR" rev-list --count HEAD..upstream/main 2>/dev/null || echo 0)
  if [[ "$behind" -gt 0 ]]; then
    echo "dotfiles-ai: your fork is $behind commit(s) behind upstream."
    echo "             Review and merge them with GitHub's 'Sync fork' button,"
    echo "             then this will pick them up on its next run."
  fi
fi

installed=$(cat "$STATE_DIR/installed-commit" 2>/dev/null || true)

if [[ $auto -eq 1 && "$after" == "$installed" ]]; then
  exit 0  # installed state already matches HEAD; stay quiet at shell startup
fi

if [[ "$before" != "$after" ]]; then
  echo "dotfiles-ai: updated ${before:0:7} -> ${after:0:7}"
fi
"$REPO_DIR/install.sh"
echo "$after" > "$STATE_DIR/installed-commit"
