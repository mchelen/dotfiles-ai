#!/usr/bin/env bash
# Behavioral tests for install.sh, derived from the acceptance criteria in
# specs/001-user-level-install/spec.md. No framework: a temp HOME per case,
# assertions that print PASS/FAIL, and a non-zero exit if anything fails.
#
#   ./test.sh

set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BEGIN_MARK="<!-- BEGIN dotfiles-ai (managed block, edit in the dotfiles-ai repo) -->"
END_MARK="<!-- END dotfiles-ai -->"
fails=0

check() { # check <name> <condition-description> <actual> <expected>
  if [[ "$3" == "$4" ]]; then
    printf 'PASS  %s\n' "$1"
  else
    printf 'FAIL  %s\n        %s: got %q, want %q\n' "$1" "$2" "$3" "$4"
    fails=$((fails + 1))
  fi
}

new_home() { mktemp -d; }
# XDG_STATE_HOME is pinned inside the throwaway HOME too: the installer keeps
# the saved module selection there, and a machine that sets XDG_STATE_HOME
# would otherwise have its real state written by the test run.
run() { env HOME="$1" XDG_STATE_HOME="$1/.local/state" "$REPO_DIR/install.sh" "${@:2}"; }
begins() { grep -cF "BEGIN dotfiles-ai" "$1" 2>/dev/null || true; }

# --- SC-002: any number of runs leaves exactly one managed block -------------
h="$(new_home)"; mkdir -p "$h/.claude"
printf '# notes\n\nabove\n' > "$h/.claude/CLAUDE.md"
for _ in 1 2 3; do run "$h" >/dev/null 2>&1; done
check "SC-002 three runs leave one block" "BEGIN count" "$(begins "$h/.claude/CLAUDE.md")" "1"

# --- SC-003: content outside the markers survives byte-for-byte --------------
outside="$(awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
  $0==b {skip=1} !skip {print} $0==e {skip=0}' "$h/.claude/CLAUDE.md" | sed '/^$/d')"
check "SC-003 content outside markers preserved" "outside text" "$outside" "$(printf '# notes\nabove')"
rm -rf "$h"

# --- FR-006 under a hand-damaged BEGIN marker (the defect) ------------------
# Detection matched the marker as a substring while removal required an exact
# line, so a trailing space made the block found-but-not-removed.
h="$(new_home)"; mkdir -p "$h/.claude"
{ printf '%s \n' "$BEGIN_MARK"; printf 'STALE-CONTENT\n'; printf '%s\n' "$END_MARK"; } > "$h/.claude/CLAUDE.md"
run "$h" >/dev/null 2>&1
check "FR-006 damaged BEGIN still leaves one block" "BEGIN count" "$(begins "$h/.claude/CLAUDE.md")" "1"
check "FR-006 damaged BEGIN drops stale content" "stale lines" \
  "$(grep -c 'STALE-CONTENT' "$h/.claude/CLAUDE.md" 2>/dev/null || true)" "0"
rm -rf "$h"

# --- unterminated block must not truncate the rest of the file --------------
h="$(new_home)"; mkdir -p "$h/.claude"
{ printf '%s\n' "$BEGIN_MARK"; printf 'orphaned\n'; printf 'KEEP-ME\n'; } > "$h/.claude/CLAUDE.md"
run "$h" >/dev/null 2>&1; rc=$?
check "unterminated block fails loudly" "exit status non-zero" "$([[ $rc -ne 0 ]] && echo yes || echo no)" "yes"
check "unterminated block keeps trailing content" "KEEP-ME present" \
  "$(grep -c 'KEEP-ME' "$h/.claude/CLAUDE.md" 2>/dev/null || true)" "1"
rm -rf "$h"

# --- FR-005 / FR-005a: print modes write nothing to disk --------------------
h="$(new_home)"; mkdir -p "$h/.claude"
run "$h" --print >/dev/null 2>&1
run "$h" --brief >/dev/null 2>&1
check "FR-005 print modes touch no target" "CLAUDE.md exists" \
  "$([[ -e "$h/.claude/CLAUDE.md" ]] && echo yes || echo no)" "no"
rm -rf "$h"

# --- FR-010: unrecognized option exits 2 ------------------------------------
h="$(new_home)"; run "$h" --nonsense >/dev/null 2>&1
check "FR-010 unknown option exits 2" "exit status" "$?" "2"
rm -rf "$h"

# --- FR-014: module selection -----------------------------------------------
# A subset can be installed, and the choice survives the next unattended run.
h="$(new_home)"; mkdir -p "$h/.claude"
run "$h" --only commit-conventions,testing >/dev/null 2>&1
body="$h/.claude/CLAUDE.md"
check "FR-014 --only installs the named modules" "commit-conventions heading" \
  "$(grep -c '^# Commit and branch conventions$' "$body" || true)" "1"
check "FR-014 --only omits the rest" "secrets heading" \
  "$(grep -c '^# Secrets' "$body" || true)" "0"

# The trap this exists to avoid: sync.sh runs install.sh with no arguments.
run "$h" >/dev/null 2>&1
check "FR-014 selection survives a bare re-run" "secrets heading" \
  "$(grep -c '^# Secrets' "$body" || true)" "0"

run "$h" --all-modules >/dev/null 2>&1
check "FR-014 --all-modules restores every module" "secrets heading" \
  "$(grep -c '^# Secrets' "$body" || true)" "1"

# --except is the complement, and print modes honor the selection.
check "FR-014 --except drops only the named module" "its heading in --print" \
  "$(run "$h" --except commit-conventions --print 2>/dev/null | grep -c '^# Commit and branch conventions$' || true)" "0"
check "FR-014 --brief honors the selection" "line count" \
  "$(run "$h" --brief --only commit-conventions,testing 2>/dev/null | grep -c '^- ' || true)" "2"

# An unknown name must stop the run: quietly installing all but one of the modules
# someone asked for is the kind of error nobody notices.
run "$h" --only testing,typo >/dev/null 2>&1
check "FR-014 unknown module exits 3" "exit status" "$?" "3"

# --list is a query — an assistant reads it while building the "which of
# these?" prompt, before anyone has decided anything.
rm -rf "$h"; h="$(new_home)"; mkdir -p "$h/.claude"
run "$h" --only testing --list >/dev/null 2>&1
check "FR-014 --list saves nothing" "state file" \
  "$([[ -e "$h/.local/state/dotfiles-ai/modules" ]] && echo yes || echo no)" "no"
check "FR-014 --list marks the selection" "checked lines" \
  "$(run "$h" --only testing --list 2>/dev/null | grep -c '^\[x\]' || true)" "1"
rm -rf "$h"

# A module can be deleted from the fork after a selection names it. Failing
# there would break every unattended sync.sh run until someone read the output.
h="$(new_home)"; mkdir -p "$h/.claude" "$h/.local/state/dotfiles-ai"
printf 'testing\nno-such-module\n' > "$h/.local/state/dotfiles-ai/modules"
run "$h" >/dev/null 2>&1
check "FR-015 stale saved name does not fail the run" "exit status" "$?" "0"
check "FR-015 stale saved name is pruned from the file" "saved names" \
  "$(tr '\n' ' ' < "$h/.local/state/dotfiles-ai/modules")" "testing "
rm -rf "$h"

# --- SC-006: the condensed form fits the smallest documented field ----------
# Adding a module is the only thing that breaks this, and the person adding one
# is not the person who later finds their settings field silently truncated.
h="$(new_home)"
brief_size="$(run "$h" --brief 2>/dev/null | wc -c | tr -d ' ')"
check "SC-006 condensed form fits the documented floor" "$brief_size characters against a 1500 floor" \
  "$([[ $brief_size -le 1500 ]] && echo fits || echo over)" "fits"
rm -rf "$h"

# --- the committed artifacts match what the installer produces --------------
# docs/index.html was checked below long before these two were, so a change
# that regenerated the site but not INSTRUCTIONS.md passed. The no-terminal
# install path reads INSTRUCTIONS.md straight out of the repo, so a stale one
# is a wrong answer served to whoever copies it.
h="$(new_home)"
full="$(mktemp)"; brief="$(mktemp)"
run "$h" --print > "$full" 2>/dev/null
run "$h" --brief > "$brief" 2>/dev/null
check "INSTRUCTIONS.md matches install.sh --print" "regenerate to fix" \
  "$(diff -q "$REPO_DIR/INSTRUCTIONS.md" "$full" >/dev/null 2>&1 && echo current || echo stale)" "current"
check "INSTRUCTIONS-brief.md matches install.sh --brief" "regenerate to fix" \
  "$(diff -q "$REPO_DIR/INSTRUCTIONS-brief.md" "$brief" >/dev/null 2>&1 && echo current || echo stale)" "current"
rm -f "$full" "$brief"; rm -rf "$h"

# --- the site carries each module's exact text, and it is current -----------
# build-site.sh injects defaults/*.md into docs/index.html. Nothing stops a
# module from being edited without the site being rebuilt, so the drift check
# runs here rather than relying on anyone remembering.
"$REPO_DIR/build-site.sh" --check >/dev/null 2>&1
check "site carries current module text" "build-site.sh --check" "$?" "0"

echo
if [[ $fails -eq 0 ]]; then echo "all checks passed"; else echo "$fails check(s) failed"; fi
exit $((fails > 0))
