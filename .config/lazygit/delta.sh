#!/bin/bash

# Lazygit pager: routes delta through the Rose Pine feature set and selects
# dark/light based on macOS appearance. The sidecar is loaded via
# `delta --config` so delta picks up the [delta "rose-pine-*"] features
# without reading the user's ~/.gitconfig. If you add delta config to
# ~/.gitconfig later, add [include] path = ... to that file pointing at
# the sidecar so it chains in.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIDECAR="$SCRIPT_DIR/rose-pine-delta.gitconfig"

if [ ! -f "$SIDECAR" ]; then
  echo "delta.sh: missing $SIDECAR" >&2
  exit 1
fi

if defaults read -g AppleInterfaceStyle &>/dev/null; then
  feature="rose-pine-main"
  bat_theme="rose-pine"
  dark_flag="--dark"
else
  feature="rose-pine-dawn"
  bat_theme="rose-pine-dawn"
  dark_flag="--light"
fi

# Only pass --syntax-theme if the matching bat .tmTheme is installed;
# otherwise delta errors and the diff is unrenderable.
syntax_flag=""
if [ -f "$HOME/.config/bat/themes/${bat_theme}.tmTheme" ]; then
  syntax_flag="--syntax-theme=$bat_theme"
fi

exec delta --config="$SIDECAR" "$dark_flag" --paging=never --features="$feature" $syntax_flag "$@"
