#!/usr/bin/env bash
# Fetches the suite's pinned plugins and parsers, and prints the directory that holds them. With
# PARHELION_TREESITTER_REF=main, nvim-treesitter comes from that branch instead of its pin.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# A GIT_DIR or GIT_WORK_TREE from the caller would send every git command below into the caller's repository.
while read -r variable; do
  unset "$variable"
done < <(git rev-parse --local-env-vars)
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

XDG_DATA_HOME="$PARHELION_DEPS/xdg/data" nvim --clean -l "$here/install_parsers.lua" >&2
echo >&2
echo "$PARHELION_DEPS"
