#!/usr/bin/env bash
# Times a load of parhelion against its floor, a colorscheme that only writes the same built groups, as the median of
# PARHELION_BENCH_RUNS fresh starts. Fails when a load fails, or when a first load takes more than 1.25 times its floor.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
runs=${PARHELION_BENCH_RUNS:-40}
cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT

lua_root=$(printf '%s' "$root" | sed 's/[\\"]/\\&/g')
mkdir -p "$cache/floor/colors"
cat >"$cache/floor/colors/parhelion_floor.lua" <<EOF
local groups = package.loaded.parhelion_floor
	or loadfile("$lua_root/lua/parhelion/built/" .. vim.o.background .. ".lua")().groups
package.loaded.parhelion_floor = groups
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
    ratio=$(awk -v a="$first" -v b="$floor_first" 'BEGIN { printf "%.2f", a / b }')
    printf "%-5s loader %-3s first load %.2f ms, floor %.2f ms, %sx | reload %.2f ms, floor %.2f ms\n" \
      "$background" "$([ "$loader" = 1 ] && echo on || echo off)" "$first" "$floor_first" "$ratio" \
      "$reload" "$floor_reload"
    if awk -v r="$ratio" 'BEGIN { exit !(r > 1.25) }'; then slow=1; fi
  done
done

if [ "$slow" = 1 ]; then
  echo "a first load takes more than 1.25 times its floor"
  exit 1
fi
