#!/usr/bin/env bash
# Runs the suite. PARHELION_TREESITTER_REF=main tests the extra queries against the newest parsers.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PARHELION_DEPS=$("${here}/fetch.sh")
export PARHELION_DEPS

exec nvim -l "${here}/run.lua"
