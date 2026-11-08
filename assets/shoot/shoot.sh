#!/usr/bin/env bash
# Shoots the README's screenshots into the directory it is given: the editor and a diff, each in dark and light.
# Neovim runs in a sandbox with its own config, data and state directories, and git with no user or system config, so
# neither reads the user's own. The plugins are the test suite's pinned dependencies. agent-browser renders each screen
# at twice its size, and oxipng compresses each image without changing a pixel.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../.." && pwd)
out=$(mkdir -p "$1" && cd "$1" && pwd)
font=${SHOOT_FONT:-Iosevka Term SS08}
session=parhelion-shoot-$$
while read -r variable; do
  unset "$variable"
done < <(git rev-parse --local-env-vars)
deps=$("$root/tests/parhelion/fetch.sh")
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

sandbox=$(mktemp -d)
trap 'agent-browser --session "$session" close >/dev/null 2>&1 || true; rm -rf "$sandbox"' EXIT

"$here/project.sh" "$sandbox/forecast"
XDG_CONFIG_HOME=$sandbox/config XDG_DATA_HOME=$sandbox/data XDG_STATE_HOME=$sandbox/state XDG_CACHE_HOME=$sandbox/cache \
  XDG_CONFIG_DIRS=$sandbox/config XDG_DATA_DIRS=$sandbox/data \
  PARHELION_ROOT=$root PARHELION_DEPS=$deps SHOOT_PROJECT=$sandbox/forecast SHOOT_FONT=$font \
  nvim --clean -l "$here/capture.lua" "$sandbox/pages"

font_found='document.fonts.ready.then(() => {
  const family = getComputedStyle(document.querySelector(".g")).fontFamily;
  const probe = document.body.appendChild(document.createElement("span"));
  probe.textContent = "mmmmmmmmmmlli";
  const width = (fallback) => {
    probe.style.font = `15px ${family}, ${fallback}`;
    return probe.getBoundingClientRect().width;
  };
  const found = width("serif") === width("monospace");
  probe.remove();
  return found;
})'

mkdir "$sandbox/shots"
agent-browser --session "$session" set viewport 1400 1000 2 >/dev/null
for page in "$sandbox"/pages/*.html; do
  name=$(basename "$page" .html)
  agent-browser --session "$session" open "file://$page" >/dev/null
  if [ "$(agent-browser --session "$session" eval "$font_found")" != true ]; then
    echo "shoot.sh: the browser has no font named $font, so the screenshots would be drawn in another" >&2
    exit 1
  fi
  agent-browser --session "$session" screenshot "#screen" "$sandbox/shots/$name.png" >/dev/null
  oxipng --quiet --opt max --strip safe "$sandbox/shots/$name.png"
done

for shot in "$sandbox"/shots/*.png; do
  mv "$shot" "$out/"
  echo "$out/$(basename "$shot")"
done
