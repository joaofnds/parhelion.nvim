#!/usr/bin/env bash
# Times a load of parhelion against its floor, a colorscheme that only writes the same built groups and clears the old
# ones first on a reload, as the median of PARHELION_BENCH_RUNS fresh starts. Fails when a load fails, or when a first
# load or a reload takes more than 1.25 times its floor.
# Exits 2 when PARHELION_BENCH_RUNS is not a whole number above 0.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
runs=${PARHELION_BENCH_RUNS:-40}
if ! [[ $runs =~ ^[1-9][0-9]*$ ]]; then
  printf 'PARHELION_BENCH_RUNS must be a whole number above 0, not "%s"\n' "$runs" >&2
  exit 2
fi
cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT

lua_root=$(printf '%s' "$root" | sed 's/[\\"]/\\&/g')
mkdir -p "$cache/floor/colors"
cat >"$cache/floor/colors/parhelion_floor.lua" <<EOF
local groups = package.loaded.parhelion_floor
	or loadfile("$lua_root/lua/parhelion/built/" .. vim.o.background .. ".lua")().groups
package.loaded.parhelion_floor = groups
if vim.g.colors_name then
	vim.cmd "hi clear"
end
vim.g.colors_name = "parhelion_floor"
for name, hl in pairs(groups) do
	vim.api.nvim_set_hl(0, name, hl)
end
EOF

once() { # colorscheme background loader
  local timings
  timings=$(PARHELION_BENCH_COLORSCHEME=$1 PARHELION_BENCH_BACKGROUND=$2 PARHELION_BENCH_LOADER=$3 \
    PARHELION_BENCH_ROOT=$root PARHELION_BENCH_FLOOR=$cache/floor XDG_CACHE_HOME=$cache nvim --headless --clean \
    --cmd "lua vim.opt.rtp:prepend { vim.env.PARHELION_BENCH_ROOT, vim.env.PARHELION_BENCH_FLOOR }" \
    -c "lua dofile(vim.env.PARHELION_BENCH_ROOT .. '/tests/parhelion/bench.lua')" -c "qa!")
  if ! awk 'NF == 2 && $1 > 0 && $2 > 0 { ok = 1 } END { exit !ok }' <<<"$timings"; then
    printf "\n%s gave no timings in %s with vim.loader %s: %s\n" "$1" "$2" "$3" "$timings" >&2
    return 1
  fi
  echo "$timings"
}

median() { # colorscheme column file
  awk -v name="$1" -v column="$2" '$1 == name { print $column }' "$3" | sort -n |
    awk '{ v[NR] = $1 } END { print NR % 2 ? v[(NR + 1) / 2] : (v[NR / 2] + v[NR / 2 + 1]) / 2 }'
}

ratio() { # time floor
  awk -v time="$1" -v floor="$2" 'BEGIN { printf "%.17g", time / floor }'
}

over_the_bound() { # ratio
  awk -v ratio="$1" 'BEGIN { exit !(ratio > 1.25) }'
}

slow=0
for background in dark light; do
  for loader in 0 1; do
    times=$cache/$background-$loader
    once parhelion "$background" "$loader" >/dev/null
    once parhelion_floor "$background" "$loader" >/dev/null
    for _ in $(seq "$runs"); do
      for colorscheme in parhelion parhelion_floor; do
        timings=$(once "$colorscheme" "$background" "$loader")
        echo "$colorscheme $timings"
      done
    done >"$times"

    first=$(median parhelion 2 "$times") floor_first=$(median parhelion_floor 2 "$times")
    reload=$(median parhelion 3 "$times") floor_reload=$(median parhelion_floor 3 "$times")
    first_ratio=$(ratio "$first" "$floor_first") reload_ratio=$(ratio "$reload" "$floor_reload")
    printf "%-5s loader %-3s first load %.2f ms, floor %.2f ms, %.3fx | reload %.2f ms, floor %.2f ms, %.3fx\n" \
      "$background" "$([ "$loader" = 1 ] && echo on || echo off)" "$first" "$floor_first" "$first_ratio" \
      "$reload" "$floor_reload" "$reload_ratio"
    if over_the_bound "$first_ratio" || over_the_bound "$reload_ratio"; then slow=1; fi
  done
done

if [ "$slow" = 1 ]; then
  echo "a first load or a reload takes more than 1.25 times its floor"
  exit 1
fi
