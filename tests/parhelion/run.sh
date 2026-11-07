#!/usr/bin/env bash
# Runs the suite. PARHELION_TREESITTER_REF=main tests the extra queries against the newest parsers.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export PARHELION_DEPS=${PARHELION_DEPS:-${XDG_CACHE_HOME:-$HOME/.cache}/parhelion-test-deps${PARHELION_TREESITTER_REF:+-$PARHELION_TREESITTER_REF}}
mkdir -p "$PARHELION_DEPS"

fetch() { # name url commit
  local dir="$PARHELION_DEPS/$1"
  if [ "$(git -C "$dir" rev-parse HEAD 2>/dev/null)" = "$3" ]; then return; fi
  rm -rf "$dir"
  git init -q "$dir"
  git -C "$dir" fetch -q --depth 1 "$2" "$3"
  git -C "$dir" -c advice.detachedHead=false checkout -q FETCH_HEAD
}

while read -r name url commit; do
  if [ "$name" = nvim-treesitter ] && [ -n "${PARHELION_TREESITTER_REF:-}" ]; then
    rm -rf "${PARHELION_DEPS:?}/$name"
    git clone -q --depth 1 --branch "$PARHELION_TREESITTER_REF" "$url" "$PARHELION_DEPS/$name"
  else
    fetch "$name" "$url" "$commit"
  fi
done <"$here/deps.txt"

XDG_DATA_HOME="$PARHELION_DEPS/xdg/data" nvim --clean -l "$here/install_parsers.lua"
echo

exec nvim -l "$here/run.lua"
