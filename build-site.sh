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
  echo "docs/index.html updated from $(ls "$REPO_DIR"/defaults/*.md | wc -l | tr -d ' ') modules"
fi
