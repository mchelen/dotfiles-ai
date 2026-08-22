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
run() { env HOME="$1" "$REPO_DIR/install.sh" "${@:2}"; }
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

# --- the site carries each module's exact text, and it is current -----------
# build-site.sh injects defaults/*.md into docs/index.html. Nothing stops a
# module from being edited without the site being rebuilt, so the drift check
# runs here rather than relying on anyone remembering.
"$REPO_DIR/build-site.sh" --check >/dev/null 2>&1
check "site carries current module text" "build-site.sh --check" "$?" "0"

echo
if [[ $fails -eq 0 ]]; then echo "all checks passed"; else echo "$fails check(s) failed"; fi
exit $((fails > 0))
