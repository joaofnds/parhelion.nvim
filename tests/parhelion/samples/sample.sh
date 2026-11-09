#!/usr/bin/env bash
# sample script
set -euo pipefail
readonly name="${1:-world}"

greet() {
  local who=$1
  printf 'hello %s\n' "${who}" | tr '[:lower:]' '[:upper:]'
}

for i in $(seq 1 3); do
  if [[ ${i} -gt 1 ]]; then greet "${name}" >&2; else echo "$((i + 1))"; fi
done
