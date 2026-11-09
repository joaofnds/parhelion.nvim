#!/usr/bin/env bash
# usage: review.sh EXPERIMENTS [OUT]. Shows each experiment in the file beside today's look, in a page where a pick says
# which is better. It shoots every view the experiments name, in dark unless REVIEW_MODE=light, into OUT, which is the
# experiments file's path without .lua and with the mode after it unless given, then serves the page from there until
# stopped. Each pick is saved to OUT/picks.json as it is made, and a later run keeps them.
set -euo pipefail
if [[ -z "${1:-}" ]]; then
  echo "usage: review.sh EXPERIMENTS [OUT]" >&2
  exit 2
fi
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "${here}/../../.." && pwd)
experiments_dir=$(dirname "$1")
experiments="$(cd "${experiments_dir}" && pwd)/${1##*/}"
mode=${REVIEW_MODE:-dark}
out=${2:-${experiments%.lua}-${mode}}
out=$(mkdir -p "${out}" && cd "${out}" && pwd)
local_env_vars=$(git rev-parse --local-env-vars)
while read -r variable; do
  unset "${variable}"
done <<<"${local_env_vars}"
deps=$("${root}/tests/parhelion/fetch.sh")
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export PARHELION_ROOT=${root} PARHELION_DEPS=${deps}

sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT

views=$(nvim --clean -l "${here}/list.lua" "${experiments}" "${out}")
xargs -n 1 -P 4 nvim --clean -l "${here}/shoot.lua" "${experiments}" "${mode}" "${sandbox}/pages" <<<"${views}"
rm -rf "${out}/shots"
"${root}/assets/shoot/screenshot.sh" "${sandbox}/pages" "${out}/shots" >/dev/null
cp "${here}/review.html" "${out}/"
python3 -I "${here}/serve.py" "${out}"
