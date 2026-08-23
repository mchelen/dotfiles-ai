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

# =============================================================================
# sync.sh — specs/002-machine-sync
#
# sync.sh had a written spec with ten functional requirements and no tests,
# while install.sh had twenty-four checks. It is the component that runs
# unattended, daily, from shell startup on every machine — the one nobody
# watches run.
#
# Each case builds a throwaway "remote": a bare repo, a source tree holding
# install.sh/sync.sh/defaults, and a clone of it. No network.
# =============================================================================

git_q() { git -c user.email=t@example.com -c user.name=test -c commit.gpgsign=false "$@"; }

new_fixture() { # prints a root dir containing origin.git/ and clone/
  local root; root="$(mktemp -d)"
  # -b main on both: without it the bare repo's HEAD points at master, the
  # push creates main, and the clone comes up with no working tree at all.
  git_q init -q -b main --bare "$root/origin.git"
  git_q init -q -b main "$root/src"
  cp "$REPO_DIR/install.sh" "$REPO_DIR/sync.sh" "$root/src/"
  mkdir -p "$root/src/defaults"
  printf '# One\n\n**First module thesis.**\n' > "$root/src/defaults/one.md"
  git_q -C "$root/src" add -A
  git_q -C "$root/src" commit -qm "init"
  git_q -C "$root/src" push -q "$root/origin.git" main
  git_q clone -q "$root/origin.git" "$root/clone"
  echo "$root"
}

publish() { # publish <root> <module-name>: add a module upstream
  printf '# %s\n\n**Thesis for %s.**\n' "$2" "$2" > "$1/src/defaults/$2.md"
  git_q -C "$1/src" add -A
  git_q -C "$1/src" commit -qm "add $2"
  git_q -C "$1/src" push -q "$1/origin.git" main
}

sync_run() { # sync_run <root> <home> [args...]
  env HOME="$2" XDG_STATE_HOME="$2/.local/state" "$1/clone/sync.sh" "${@:3}"
}

# --- FR-001/FR-002/SC-001: a published change is pulled and installed --------
r="$(new_fixture)"; h="$(new_home)"; mkdir -p "$h/.claude"
publish "$r" two
out="$(sync_run "$r" "$h" 2>&1)"
check "FR-002 sync installs what it pulled" "new module in CLAUDE.md" \
  "$(grep -c '^# two$' "$h/.claude/CLAUDE.md" 2>/dev/null || true)" "1"
# --- FR-007: the move is reported as a commit range -------------------------
check "FR-007 sync reports the commit range" "output shape" \
  "$(echo "$out" | grep -cE 'updated [0-9a-f]{7} -> [0-9a-f]{7}' || true)" "1"

# --- FR-006: the installed commit is recorded -------------------------------
check "FR-006 installed commit recorded" "matches clone HEAD" \
  "$(cat "$h/.local/state/dotfiles-ai/installed-commit" 2>/dev/null || true)" \
  "$(git -C "$r/clone" rev-parse HEAD)"

# --- FR-005/SC-002: nothing to do in auto mode is silent --------------------
check "FR-005 auto mode is silent when current" "bytes of output" \
  "$(sync_run "$r" "$h" --auto 2>&1 | wc -c | tr -d ' ')" "0"
rm -rf "$r" "$h"

# --- FR-003/SC-003: at most one attempt per interval ------------------------
# The second run must not pull, even though there is something to pull.
r="$(new_fixture)"; h="$(new_home)"; mkdir -p "$h/.claude"
sync_run "$r" "$h" --auto >/dev/null 2>&1          # first attempt: stamps
publish "$r" three
sync_run "$r" "$h" --auto >/dev/null 2>&1          # throttled: must not pull
check "FR-003 auto throttles within the interval" "three.md pulled" \
  "$([[ -e "$r/clone/defaults/three.md" ]] && echo yes || echo no)" "no"
# …and does pull once the interval is past.
DOTFILES_AI_SYNC_INTERVAL=0 env HOME="$h" XDG_STATE_HOME="$h/.local/state" \
  DOTFILES_AI_SYNC_INTERVAL=0 "$r/clone/sync.sh" --auto >/dev/null 2>&1
check "FR-003 auto syncs once the interval passes" "three.md pulled" \
  "$([[ -e "$r/clone/defaults/three.md" ]] && echo yes || echo no)" "yes"
rm -rf "$r" "$h"

# --- FR-004: the window starts at the attempt, not the success --------------
# A failing sync must still stamp, or an unreachable remote means retrying
# every single shell start.
r="$(new_fixture)"; h="$(new_home)"; mkdir -p "$h/.claude"
git_q -C "$r/clone" remote set-url origin "$r/does-not-exist.git"
sync_run "$r" "$h" --auto >/dev/null 2>&1
check "FR-004 a failed attempt still stamps" "stamp file" \
  "$([[ -e "$h/.local/state/dotfiles-ai/last-sync" ]] && echo yes || echo no)" "yes"

# --- FR-005/SC-004: offline in auto mode is silent and successful -----------
rm -f "$h/.local/state/dotfiles-ai/last-sync"
out="$(sync_run "$r" "$h" --auto 2>&1)"; rc=$?
check "SC-004 offline auto mode stays quiet" "bytes of output" "$(printf '%s' "$out" | wc -c | tr -d ' ')" "0"
check "SC-004 offline auto mode exits zero" "exit status" "$rc" "0"

# --- FR-008: manual mode says so, on stderr, non-zero -----------------------
err="$(sync_run "$r" "$h" 2>&1 >/dev/null)"; rc=$?
check "FR-008 manual mode reports a failed update" "message" \
  "$(printf '%s' "$err" | grep -c 'git pull failed' || true)" "1"
check "FR-008 manual mode exits non-zero" "exit status" \
  "$([[ $rc -ne 0 ]] && echo yes || echo no)" "yes"
rm -rf "$r" "$h"

# --- SC-005: local commits are never discarded ------------------------------
# --ff-only is the whole protection here; diverged history must abort, not
# reset. The clone is someone's machine, and it may hold work.
r="$(new_fixture)"; h="$(new_home)"; mkdir -p "$h/.claude"
printf '# Local\n\n**Local only.**\n' > "$r/clone/defaults/local.md"
git_q -C "$r/clone" add -A
git_q -C "$r/clone" commit -qm "local work"
local_sha="$(git -C "$r/clone" rev-parse HEAD)"
publish "$r" upstream          # diverges: both sides have new commits
sync_run "$r" "$h" >/dev/null 2>&1
check "SC-005 diverged history keeps local commits" "clone HEAD unchanged" \
  "$(git -C "$r/clone" rev-parse HEAD)" "$local_sha"
check "SC-005 local file survives" "local.md present" \
  "$([[ -e "$r/clone/defaults/local.md" ]] && echo yes || echo no)" "yes"
rm -rf "$r" "$h"

# --- FR-010: sync's own pull must not trigger a second sync -----------------
# The post-merge hook re-runs the installer after a manual pull. Without a
# guard, sync.sh's own pull fires it too. The hook here records what it saw.
r="$(new_fixture)"; h="$(new_home)"; mkdir -p "$h/.claude"
cat > "$r/clone/.git/hooks/post-merge" <<'HOOK'
#!/usr/bin/env bash
echo "${DOTFILES_AI_SYNC:-unset}" >> "$(git rev-parse --show-toplevel)/hook-saw"
HOOK
chmod +x "$r/clone/.git/hooks/post-merge"
publish "$r" guarded
sync_run "$r" "$h" >/dev/null 2>&1
check "FR-010 sync marks its own pull for the hook" "value the hook saw" \
  "$(cat "$r/clone/hook-saw" 2>/dev/null || echo "hook did not run")" "1"

# --- FR-009: the superseded core.hooksPath setting is cleared ---------------
git_q -C "$r/clone" config core.hooksPath .githooks
sync_run "$r" "$h" >/dev/null 2>&1
check "FR-009 legacy core.hooksPath is unset" "config value" \
  "$(git -C "$r/clone" config --get core.hooksPath || echo unset)" "unset"
rm -rf "$r" "$h"

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
