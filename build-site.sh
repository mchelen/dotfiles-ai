#!/usr/bin/env bash
# Put the exact text of every module into its card on the website.
#
# The site used to describe each module in its own prose. A reader could not
# see what would actually be installed, and the description drifted the moment
# the module changed. Each card now carries the module verbatim, between
# markers this script fills — the same technique install.sh uses on instruction
# files, turned on the project's own page.
#
# Usage:
#   ./build-site.sh          rewrite docs/index.html in place
#   ./build-site.sh --check  exit non-zero if it would change anything

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE="$REPO_DIR/docs/index.html"

check=0
case "${1:-}" in
  --check) check=1 ;;
  "")      ;;
  *)       echo "unknown option: $1" >&2; exit 2 ;;
esac

work="$(mktemp)"; cp "$SITE" "$work"
trap 'rm -f "$work" "$work.next"' EXIT

for f in "$REPO_DIR"/defaults/*.md; do
  name="$(basename "$f" .md)"
  begin="      <!-- BEGIN module-text: $name -->"
  end="      <!-- END module-text: $name -->"

  grep -qF "$begin" "$work" || { echo "no module-text markers for $name in docs/index.html" >&2; exit 3; }

  lines="$(wc -l < "$f" | tr -d ' ')"
  # Only the five characters that can break out of a <pre> need escaping.
  body="$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$f")"
  block="      <details class=\"module-text\">
        <summary>Exact text — ${lines} lines, verbatim as installed</summary>
        <pre>${body}</pre>
      </details>"

  awk -v begin="$begin" -v end="$end" -v block="$block" '
    $0 == begin { print; print block; skip = 1; next }
    $0 == end   { print; skip = 0; next }
    !skip { print }
  ' "$work" > "$work.next"
  mv "$work.next" "$work"
done

# The web-chat section quotes the size of both generated artifacts, and every
# cap they clear or miss. Hand-typed, those numbers were wrong within two
# changes of being written — so they are computed here from the artifacts
# themselves and substituted into <span data-gen="KEY"> elements.
commas() { echo "$1" | sed -e :a -e 's/\B[0-9]\{3\}\>/,&/;ta'; }

full=$(( $("$REPO_DIR/install.sh" --print | wc -c) ))
brief=$(( $("$REPO_DIR/install.sh" --brief 2>/dev/null | wc -c) ))
set_gen() { # set_gen <key> <text>
  sed -i "s|<span data-gen=\"$1\">[^<]*</span>|<span data-gen=\"$1\">$2</span>|g" "$work"
}
set_gen full  "$(commas "$full")"
set_gen brief "$(commas "$brief")"
for cap in 8000 5000 1500; do
  set_gen "over-$cap" "$(commas $(( full - cap )))"
done

# --- docs/changelog.html --------------------------------------------------
# The changelog module says to publish the changelog where users are, not only
# in the repo. Rather than keep a second copy of the site's CSS, this lifts the
# <style> block straight out of index.html, so the page cannot drift out of
# step with the rest of the site.
#
# The markdown converter handles exactly the subset CHANGELOG.md uses and
# refuses anything else. A silent miss would publish raw markdown to a live
# page; failing the build is the cheaper mistake.
CHANGELOG="$REPO_DIR/CHANGELOG.md"
CHANGELOG_OUT="$REPO_DIR/docs/changelog.html"
clog="$(mktemp)"; trap 'rm -f "$work" "$work.next" "$clog"' EXIT

if unsupported="$(grep -nE '^(>|    |\||#{4,} |\* |[0-9]+\. |```)' "$CHANGELOG")"; then
  echo "CHANGELOG.md uses markdown build-site.sh cannot render:" >&2
  echo "$unsupported" >&2
  exit 4
fi

# Escape, then join wrapped lines into blocks, and only then convert inline
# spans. Doing the inline pass first silently left `**bold**` as literal
# asterisks whenever the emphasis happened to straddle a line wrap.
body="$(sed -e 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$CHANGELOG" | awk '
    # Markdown wraps lines; HTML paragraphs and list items do not. Everything
    # is buffered until the next block starts, so a wrapped paragraph stays one
    # <p> and a wrapped list item stays one <li>. Doing this with getline
    # instead meant the line after a continuation never got re-classified.
    function close_list() { if (in_list) { print "</ul>"; in_list = 0 } }
    function flush(  t) {
      if (buf == "") return
      t = buf; buf = ""
      if (t ~ /^### /) { close_list(); sub(/^### /, "", t); printf "<h3>%s</h3>\n", t }
      else if (t ~ /^## /) {
        close_list(); sub(/^## /, "", t)
        gsub(/^\[|\]$/, "", t)          # [Unreleased] reads better unbracketed
        printf "<h2>%s</h2>\n", t
      }
      else if (t ~ /^# /) { close_list() }        # the page supplies its own h1
      else if (t ~ /^- /) {
        if (!in_list) { print "<ul>"; in_list = 1 }
        sub(/^- /, "", t); printf "<li>%s</li>\n", t
      }
      else { close_list(); printf "<p>%s</p>\n", t }
    }
    /^$/                 { flush(); close_list(); next }
    /^(#{1,3} |- )/      { flush(); buf = $0; next }
    { sub(/^[[:space:]]+/, ""); buf = (buf == "" ? $0 : buf " " $0) }
    END { flush(); close_list() }
  ' | sed \
      -e 's/`\([^`]*\)`/<code>\1<\/code>/g' \
      -e 's/\*\*\([^*]*\)\*\*/<strong>\1<\/strong>/g' \
      -e 's/\[\([^]]*\)\](\([^)]*\))/<a href="\2">\1<\/a>/g')"

# Anything the converter did not understand would be published as literal
# markdown on a live page. Catch it here rather than in a screenshot.
if leftover="$(printf '%s' "$body" | grep -nE '\*\*|`|\]\(')"; then
  echo "changelog markdown survived conversion — the converter missed something:" >&2
  printf '%s\n' "$leftover" >&2
  exit 5
fi

{
  printf '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
  printf '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
  printf '<title>Changelog — dotfiles-ai</title>\n'
  sed -n '/^<style>$/,/^<\/style>$/p' "$SITE"
  printf '</head>\n<body>\n<header>\n'
  printf '  <h1>Changelog<span class="dot">.</span></h1>\n'
  printf '  <p class="tagline">What changed in dotfiles-ai, and when.</p>\n'
  printf '  <div class="buttons"><a class="btn" href="./">Back to the guide</a>'
  printf '<a class="btn" href="https://github.com/mchelen/dotfiles-ai/blob/main/CHANGELOG.md">CHANGELOG.md</a></div>\n'
  printf '</header>\n<main>\n<section>\n'
  printf '%s\n' "$body"
  printf '</section>\n</main>\n'
  printf '<footer>Generated from <code>CHANGELOG.md</code> by <code>build-site.sh</code>. '
  printf 'Edit the markdown, not this page.</footer>\n</body>\n</html>\n'
} > "$clog"

if [[ $check -eq 1 ]]; then
  if ! diff -q "$CHANGELOG_OUT" "$clog" >/dev/null 2>&1; then
    echo "docs/changelog.html is stale — run ./build-site.sh" >&2
    exit 1
  fi
fi

if [[ $check -eq 1 ]]; then
  if diff -q "$SITE" "$work" >/dev/null; then
    echo "docs/index.html is current"
  else
    echo "docs/index.html is stale — run ./build-site.sh" >&2
    diff -u "$SITE" "$work" | head -40 >&2
    exit 1
  fi
else
  cat "$work" > "$SITE"
  cat "$clog" > "$CHANGELOG_OUT"
  echo "docs/index.html updated from $(ls "$REPO_DIR"/defaults/*.md | wc -l | tr -d ' ') modules"
  echo "docs/changelog.html updated from CHANGELOG.md"
fi
