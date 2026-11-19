#!/bin/sh
# Renders one page to PNG at its own content height.
# Usage: render.sh <page.html>[?query] <out.png> [css-width=1080] [scale=2]
# The query picks one example from a page that holds several, e.g. 'page.html?chart=stacked'.
# Always render the whole page: an element screenshot drops the page padding.
# The page must set body[data-height] and body[data-fonts] once document.fonts is ready
# (both templates do). Uses Google Chrome headless; override with CHROME_PATH.
set -eu

case "$1" in *\?*) file="${1%%\?*}" query="?${1#*\?}" ;; *) file="$1" query="" ;; esac
src="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"

# Inter and Geist Mono come from the Google Fonts repository and are cached after the first run.
fonts_dir="${XDG_CACHE_HOME:-$HOME/.cache}/presenting-pr-changes/fonts"
gf="https://raw.githubusercontent.com/google/fonts/main/ofl"
mkdir -p "$fonts_dir"
fetch() { # <file> <url>
  [ -s "$fonts_dir/$1" ] && return 0
  curl -fsSL --retry 2 -o "$fonts_dir/$1.part" "$2" && mv "$fonts_dir/$1.part" "$fonts_dir/$1" \
    || { rm -f "$fonts_dir/$1.part"; echo "could not download $1 from Google Fonts" >&2; exit 1; }
}
fetch Inter.ttf "$gf/inter/Inter%5Bopsz,wght%5D.ttf"
fetch GeistMono.ttf "$gf/geistmono/GeistMono%5Bwght%5D.ttf"

# Templates reference fonts as file://{{FONTS}}/...; fill in the cache path on a throwaway copy.
page="$(dirname "$src")/.render-$$.html"
trap 'rm -f "$page"' EXIT
sed "s|{{FONTS}}|$fonts_dir|g" "$src" > "$page"
mkdir -p "$(dirname "$2")"
out="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
width="${3:-1080}"
scale="${4:-2}"
chrome="${CHROME_PATH:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

dom="$("$chrome" --headless=new --disable-gpu --allow-file-access-from-files \
  --window-size="$width,4000" --virtual-time-budget=3000 --dump-dom "file://$page$query" 2>/dev/null)"
height="$(printf '%s' "$dom" | sed -n 's/.*data-height="\([0-9]*\)".*/\1/p' | head -1)"
fonts="$(printf '%s' "$dom" | sed -n 's/.*data-fonts="\([a-z]*\)".*/\1/p' | head -1)"
error="$(printf '%s' "$dom" | sed -n 's/.*data-error="\([^"]*\)".*/\1/p' | head -1)"
[ -z "$error" ] || { echo "page refused to render: $error" >&2; exit 1; }
[ -n "$height" ] || { echo "page never set body[data-height]" >&2; exit 1; }
[ "$fonts" = "true" ] || { echo "Inter or Geist Mono did not load" >&2; exit 1; }

"$chrome" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
  --window-size="$width,$height" --force-device-scale-factor="$scale" \
  --screenshot="$out" "file://$page$query" >/dev/null 2>&1
echo "$out $((width * scale))x$((height * scale))"
