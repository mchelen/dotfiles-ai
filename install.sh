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
#   ./install.sh                  install/update the managed block for detected tools
#   ./install.sh --all            install for every known tool, detected or not
#   ./install.sh --print          print the assembled block to stdout and exit
#   ./install.sh --brief          print the condensed one-line-per-module block and exit
#   ./install.sh --list           list the modules, marking which are selected
#   ./install.sh --only a,b       use only these modules (remembered)
#   ./install.sh --except a,b     use every module but these (remembered)
#   ./install.sh --all-modules    forget any saved selection and use all modules
#
# Not everyone wants every module. A selection made with --only or
# --except is saved, because sync.sh re-runs this script unattended: a
# selection that lasted until the next daily sync would be a trap, not a
# feature. The durable way to curate is still to delete modules you don't want
# from defaults/ in your fork; the saved selection is for keeping a subset on
# one machine without changing the repo.

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

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-ai"
SELECTION_FILE="$STATE_DIR/modules"

all_modules() { # every module name, in filename order
  local f
  for f in "$REPO_DIR"/defaults/*.md; do
    [[ -f "$f" ]] || continue
    basename "$f" .md
  done
}

# The module names to use, one per line. Set by resolve_selection().
SELECTED=()
selection_source=""

# Turn --only / --except / a saved selection into SELECTED, rejecting names
# that don't exist. A typo must fail loudly: silently installing all but one of
# the modules someone asked for is the kind of error nobody notices.
resolve_selection() { # resolve_selection <only-csv> <except-csv> <forget:0|1>
  local only="$1" except="$2" forget="$3"
  local -a available; mapfile -t available < <(all_modules)
  [[ ${#available[@]} -gt 0 ]] || { echo "no modules found in $REPO_DIR/defaults/" >&2; return 1; }

  if [[ $forget -eq 1 ]]; then
    SELECTED=("${available[@]}"); selection_source="all"; return 0
  fi

  if [[ -z "$only" && -z "$except" && -s "$SELECTION_FILE" ]]; then
    mapfile -t only_names < "$SELECTION_FILE"
    only="$(IFS=,; echo "${only_names[*]}")"
    selection_source="saved"
  elif [[ -n "$only" || -n "$except" ]]; then
    selection_source="flag"
  else
    SELECTED=("${available[@]}"); selection_source="all"; return 0
  fi

  local -a named; IFS=',' read -r -a named <<< "${only:-$except}"
  local n known
  local -a kept=()
  for n in "${named[@]}"; do
    [[ -n "$n" ]] || continue
    known=0
    for m in "${available[@]}"; do [[ "$m" == "$n" ]] && known=1; done
    if [[ $known -eq 1 ]]; then
      kept+=("$n")
    elif [[ "$selection_source" == "saved" ]]; then
      # A saved selection names modules, and a module can be deleted from the
      # fork after the selection was made. Failing there would break every
      # unattended sync.sh run until someone noticed; the name is simply gone.
      echo "saved selection names $n, which no longer exists — dropping it" >&2
    else
      echo "unknown module: $n" >&2
      echo "available: $(IFS=,; echo "${available[*]}")" >&2
      return 3
    fi
  done
  named=("${kept[@]+"${kept[@]}"}")

  SELECTED=()
  for m in "${available[@]}"; do
    local wanted=0
    for n in "${named[@]}"; do [[ "$m" == "$n" ]] && wanted=1; done
    if [[ -n "$only" ]]; then
      [[ $wanted -eq 1 ]] && SELECTED+=("$m")
    else
      [[ $wanted -eq 0 ]] && SELECTED+=("$m")
    fi
  done

  if [[ ${#SELECTED[@]} -eq 0 ]]; then
    echo "that selection leaves no modules — nothing to install" >&2
    return 3
  fi


}

# Only an actual install writes the saved selection. --print / --brief / --list
# are queries: an assistant reads them while building the "which of these?"
# prompt, long before anyone has decided anything.
remember_selection() { # remember_selection <forget:0|1>
  if [[ "$1" -eq 1 ]]; then rm -f "$SELECTION_FILE"; return 0; fi
  [[ "$selection_source" == "all" ]] && return 0
  # Written on every install, not only when a flag set it: an --except list and
  # a saved list that has been pruned both resolve to names worth writing back,
  # so the file converges on what is actually installed.
  mkdir -p "$STATE_DIR"
  printf '%s\n' "${SELECTED[@]}" > "$SELECTION_FILE"
}

selected_files() { local m; for m in "${SELECTED[@]}"; do echo "$REPO_DIR/defaults/$m.md"; done; }

# Modules are flat files in defaults/; categories are a documentation
# concept (see the README), not a directory layout.
assemble() {
  local f
  echo "$BEGIN_MARK"
  while read -r f; do
    cat "$f"
    echo
  done < <(selected_files)
  echo "$END_MARK"
}

# One line per module: the name, then its thesis sentence. This is what an
# assistant reads to build the "which of these do you want?" list, so it has
# to be parseable without knowing anything about markdown.
list_modules() {
  local m mark
  for m in $(all_modules); do
    mark=" "
    for sel in "${SELECTED[@]}"; do [[ "$sel" == "$m" ]] && mark="x"; done
    printf '[%s] %-24s %s\n' "$mark" "$m" "$(thesis "$REPO_DIR/defaults/$m.md")"
  done
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
thesis() { # the bold paragraph under a module's heading, unwrapped to one line
  local line
  line="$(awk '
    /^\*\*/ && !done {
      buf = $0
      while (buf !~ /\*\*[[:space:]]*$/) { if ((getline nxt) <= 0) break; buf = buf " " nxt }
      sub(/^\*\*/, "", buf); sub(/\*\*[[:space:]]*$/, "", buf)
      print buf; done = 1
    }' "$1")"
  if [[ -z "$line" ]]; then
    echo "no thesis sentence (a **bold** paragraph under the heading) in $1" >&2
    return 1
  fi
  echo "$line"
}

brief() {
  local f
  echo "My working defaults (dotfiles-ai). Follow these unless I say otherwise."
  echo
  while read -r f; do
    echo "- $(thesis "$f")"
  done < <(selected_files)
}

# Remove an existing managed block from $1, writing the remainder to $2, and
# print one of: replaced | absent | unterminated.
#
# Detection and removal deliberately share a single comparison. They used to
# differ — a substring grep decided whether a block was present, an exact-line
# awk removed it — so a marker line carrying trailing whitespace was found but
# not removed: the run reported success, left the stale block in place, and
# appended a second one. Markers are now compared with surrounding whitespace
# trimmed, so a hand-touched file still round-trips.
#
# A BEGIN with no matching END is reported rather than acted on. The old code
# skipped to end-of-file in that case, silently deleting everything below the
# marker.
strip_block() {
  awk -v begin="$BEGIN_MARK" -v end="$END_MARK" -v out="$2" '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    BEGIN { printf "" > out }
    { line = trim($0) }
    !skip && line == begin { skip = 1; found = 1; next }
    skip  && line == end   { skip = 0; next }
    !skip { print > out }
    END {
      if (skip)       print "unterminated"
      else if (found) print "replaced"
      else            print "absent"
    }
  ' "$1"
}

install_all=0
action="install"
only=""
except=""
forget=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --print)       action="print" ;;
    --brief)       action="brief" ;;
    --list)        action="list" ;;
    --all)         install_all=1 ;;
    --all-modules) forget=1 ;;
    --only)        only="${2:-}"; shift ;;
    --only=*)      only="${1#*=}" ;;
    --except)      except="${2:-}"; shift ;;
    --except=*)    except="${1#*=}" ;;
    *)             echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if [[ -n "$only" && -n "$except" ]]; then
  echo "--only and --except are alternatives; pass one" >&2; exit 2
fi

resolve_selection "$only" "$except" "$forget"

case "$action" in
  print) assemble; exit 0 ;;
  brief) brief; exit 0 ;;
  list)  list_modules; exit 0 ;;
esac

remember_selection "$forget"
block="$(assemble)"

if [[ ${#SELECTED[@]} -lt $(all_modules | wc -l) ]]; then
  case "$selection_source" in
    saved) echo "using your saved selection: $(IFS=,; echo "${SELECTED[*]}")" ;;
    flag)  echo "installing these modules, and remembering the choice: $(IFS=,; echo "${SELECTED[*]}")" ;;
  esac
  echo "(./install.sh --all-modules restores every module)"
  echo
fi

for target in "${TARGETS[@]}"; do
  dir="$(dirname "$target")"

  if [[ ! -d "$dir" && "$install_all" -eq 0 ]]; then
    echo "skipped  $target (no $dir — tool not detected; use --all to force)"
    continue
  fi

  mkdir -p "$dir"
  touch "$target"

  tmp="$(mktemp)"
  case "$(strip_block "$target" "$tmp")" in
    replaced)
      cp "$target" "$target.bak"
      cat "$tmp" > "$target"          # write through, keeping mode and symlinks
      rm -f "$tmp"
      echo "updated  $target (previous version saved to $target.bak)"
      ;;
    absent)
      rm -f "$tmp"
      echo "installed $target"
      ;;
    unterminated)
      rm -f "$tmp"
      echo "$target has a BEGIN marker with no matching END." >&2
      echo "Refusing to touch it: removing the block would delete everything below" >&2
      echo "the marker. Fix the file by hand (or restore $target.bak) and re-run." >&2
      exit 4
      ;;
    *)
      rm -f "$tmp"
      echo "could not read $target" >&2
      exit 5
      ;;
  esac

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
