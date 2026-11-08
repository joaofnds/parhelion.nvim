#!/usr/bin/env bash
# Shoots the README's screenshots into the directory it is given: the editor and a diff, each in dark and light.
# Neovim runs in a sandbox with its own config, data and state directories, so it never reads the user's own, and takes
# its plugins from the test suite's pinned dependencies. agent-browser renders each screen at twice its size.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../.." && pwd)
out=$(mkdir -p "$1" && cd "$1" && pwd)
deps=${PARHELION_DEPS:-$HOME/.cache/parhelion-test-deps}
font=${SHOOT_FONT:-Iosevka Term SS08}
session=parhelion-shoot-$$

sandbox=$(mktemp -d)
trap 'agent-browser --session "$session" close >/dev/null 2>&1 || true; rm -rf "$sandbox"' EXIT

"$here/project.sh" "$sandbox/forecast"
XDG_CONFIG_HOME=$sandbox/config XDG_DATA_HOME=$sandbox/data XDG_STATE_HOME=$sandbox/state XDG_CACHE_HOME=$sandbox/cache \
  PARHELION_ROOT=$root PARHELION_DEPS=$deps SHOOT_PROJECT=$sandbox/forecast SHOOT_FONT=$font \
  nvim --clean -l "$here/capture.lua" "$sandbox/pages"

agent-browser --session "$session" set viewport 1400 1000 2 >/dev/null
for page in "$sandbox"/pages/*.html; do
  name=$(basename "$page" .html)
  agent-browser --session "$session" open "file://$page" >/dev/null
  agent-browser --session "$session" eval "document.fonts.ready.then(() => true)" >/dev/null
  agent-browser --session "$session" screenshot "#screen" "$out/$name.png" >/dev/null
  echo "$out/$name.png"
done
