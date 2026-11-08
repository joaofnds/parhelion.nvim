#!/usr/bin/env bash
# Times a load of parhelion against its floor, a colorscheme that only writes the same built groups, as the median of
# PARHELION_BENCH_RUNS fresh starts. Fails when a first load takes more than 1.5 times its floor.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
runs=${PARHELION_BENCH_RUNS:-40}
cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT

mkdir -p "$cache/floor/colors"
cat >"$cache/floor/colors/parhelion_floor.lua" <<EOF
local groups = package.loaded.parhelion_floor
	or loadfile("$root/lua/parhelion/built/" .. vim.o.background .. ".lua")().groups
package.loaded.parhelion_floor = groups
for name, hl in pairs(groups) do
	vim.api.nvim_set_hl(0, name, hl)
end
EOF

once() { # colorscheme background loader
  PARHELION_BENCH_COLORSCHEME=$1 PARHELION_BENCH_BACKGROUND=$2 PARHELION_BENCH_LOADER=$3 XDG_CACHE_HOME=$cache \
    nvim --headless --clean --cmd "set rtp^=$root,$cache/floor" -c "luafile $root/tests/parhelion/bench.lua" -c "qa!"
}

median() { # colorscheme column file
  awk -v name="$1" -v column="$2" '$1 == name { print $column }' "$3" | sort -n |
    awk '{ v[NR] = $1 } END { print v[int((NR + 1) / 2)] }'
}

slow=0
for background in dark light; do
  for loader in 0 1; do
    times=$cache/$background-$loader
    once parhelion "$background" "$loader" >/dev/null
    once parhelion_floor "$background" "$loader" >/dev/null
    for _ in $(seq "$runs"); do
      echo "parhelion $(once parhelion "$background" "$loader")"
      echo "parhelion_floor $(once parhelion_floor "$background" "$loader")"
    done >"$times"

    first=$(median parhelion 2 "$times") floor_first=$(median parhelion_floor 2 "$times")
    reload=$(median parhelion 3 "$times") floor_reload=$(median parhelion_floor 3 "$times")
    ratio=$(awk -v a="$first" -v b="$floor_first" 'BEGIN { printf "%.2f", a / b }')
    printf "%-5s loader %-3s first load %.2f ms, floor %.2f ms, %sx | reload %.2f ms, floor %.2f ms\n" \
      "$background" "$([ "$loader" = 1 ] && echo on || echo off)" "$first" "$floor_first" "$ratio" "$reload" "$floor_reload"
    if awk -v r="$ratio" 'BEGIN { exit !(r > 1.5) }'; then slow=1; fi
  done
done

if [ "$slow" = 1 ]; then
  echo "a first load takes more than 1.5 times its floor"
  exit 1
fi
