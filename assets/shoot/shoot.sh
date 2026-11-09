#!/usr/bin/env bash
# Shoots the README's screenshots into the directory it is given: the editor and a diff, each in dark and light.
# Neovim runs in a sandbox with its own config, data and state directories, and git with no user or system config, so
# neither reads the user's own. The plugins are the test suite's pinned dependencies. screenshot.sh turns each screen
# into an image, and oxipng compresses each image without changing a pixel.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "${here}/../.." && pwd)
out=$(mkdir -p "$1" && cd "$1" && pwd)
font=${SHOOT_FONT:-Iosevka Term SS08}
local_env_vars=$(git rev-parse --local-env-vars)
while read -r variable; do
  unset "${variable}"
done <<<"${local_env_vars}"
deps=$("${root}/tests/parhelion/fetch.sh")
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT

"${here}/project.sh" "${sandbox}/forecast"
XDG_CONFIG_HOME=${sandbox}/config XDG_DATA_HOME=${sandbox}/data XDG_STATE_HOME=${sandbox}/state XDG_CACHE_HOME=${sandbox}/cache \
  XDG_CONFIG_DIRS=${sandbox}/config XDG_DATA_DIRS=${sandbox}/data \
  PARHELION_ROOT=${root} PARHELION_DEPS=${deps} SHOOT_PROJECT=${sandbox}/forecast SHOOT_FONT=${font} \
  nvim --clean -l "${here}/capture.lua" "${sandbox}/pages"

"${here}/screenshot.sh" "${sandbox}/pages" "${sandbox}/shots" >/dev/null
for shot in "${sandbox}"/shots/*.png; do
  oxipng --quiet --opt max --strip safe "${shot}"
  mv "${shot}" "${out}/"
  echo "${out}/$(basename "${shot}")"
done
