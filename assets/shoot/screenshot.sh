#!/usr/bin/env bash
# Turns each HTML page page.lua wrote in the first directory it is given into a PNG of the same name in the second.
# agent-browser draws each screen at twice its size, and refuses a page whose font the browser lacks, since the image
# would be drawn in another.
set -euo pipefail
pages=$(cd "$1" && pwd)
shots=$(mkdir -p "$2" && cd "$2" && pwd)
session=parhelion-screenshot-$$
trap 'agent-browser --session "$session" close >/dev/null 2>&1 || true' EXIT

missing_font=$(
  cat <<'JS'
document.fonts.ready.then(() => {
  const family = getComputedStyle(document.querySelector(".g")).fontFamily;
  const probe = document.body.appendChild(document.createElement("span"));
  probe.textContent = "mmmmmmmmmmlli";
  const width = (fallback) => {
    probe.style.font = `15px ${family}, ${fallback}`;
    return probe.getBoundingClientRect().width;
  };
  const found = width("serif") === width("monospace");
  probe.remove();
  return found ? "" : family.replaceAll('"', "");
})
JS
)

agent-browser --session "${session}" set viewport 1400 1000 2 >/dev/null
for page in "${pages}"/*.html; do
  name=$(basename "${page}" .html)
  agent-browser --session "${session}" open "file://${page}" >/dev/null
  missing=$(agent-browser --session "${session}" eval "${missing_font}")
  if [[ "${missing}" != '""' ]]; then
    echo "screenshot.sh: the browser has no font named ${missing}, so the screenshots would be drawn in another" >&2
    exit 1
  fi
  agent-browser --session "${session}" screenshot "#screen" "${shots}/${name}.png" >/dev/null
  echo "${shots}/${name}.png"
done
