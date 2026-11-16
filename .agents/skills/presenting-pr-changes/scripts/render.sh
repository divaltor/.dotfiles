#!/bin/sh
# Renders one page to PNG at its own content height.
# Usage: render.sh <page.html> <out.png> [css-width=1080] [scale=2]
# The page must set body[data-height] and body[data-fonts] once document.fonts is ready
# (both templates do). Uses Google Chrome headless; override with CHROME_PATH.
set -eu

page="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
mkdir -p "$(dirname "$2")"
out="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
width="${3:-1080}"
scale="${4:-2}"
chrome="${CHROME_PATH:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

for font in IBMPlexSans-Regular IBMPlexSans-Medium IBMPlexSans-SemiBold IoskeleyMono-Regular IoskeleyMono-Medium; do
  [ -f "$HOME/Library/Fonts/$font.ttf" ] || { echo "missing ~/Library/Fonts/$font.ttf" >&2; exit 1; }
done

dom="$("$chrome" --headless=new --disable-gpu --allow-file-access-from-files \
  --window-size="$width,4000" --virtual-time-budget=3000 --dump-dom "file://$page" 2>/dev/null)"
height="$(printf '%s' "$dom" | sed -n 's/.*data-height="\([0-9]*\)".*/\1/p' | head -1)"
fonts="$(printf '%s' "$dom" | sed -n 's/.*data-fonts="\([a-z]*\)".*/\1/p' | head -1)"
[ -n "$height" ] || { echo "page never set body[data-height]" >&2; exit 1; }
[ "$fonts" = "true" ] || { echo "IBM Plex Sans or Ioskeley Mono did not load" >&2; exit 1; }

"$chrome" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
  --window-size="$width,$height" --force-device-scale-factor="$scale" \
  --screenshot="$out" "file://$page" >/dev/null 2>&1
echo "$out $((width * scale))x$((height * scale))"
