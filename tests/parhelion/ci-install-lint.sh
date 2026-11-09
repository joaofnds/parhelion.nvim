#!/usr/bin/env bash
# Installs the shfmt, ShellCheck and lua-language-server the format check and the lint run with under ~/.local, checked
# against the checksums it pins, and prints the versions it installed. The lint also needs the Neovim ci-install.sh
# installs, for the runtime it type-checks against.
set -euo pipefail
shfmt_version=v3.14.1
shellcheck_version=v0.11.0
lua_language_server_version=3.19.2
prefix=${HOME}/.local

machine=$(uname -m)
case "${machine}" in
x86_64)
  shfmt_platform=linux_amd64
  shfmt_sha256=76e77641faa025814b77f153b29796b8e6fa2fca03e0c76a691608b86c7ea7bf
  shellcheck_sha256=b7af85e41cc99489dcc21d66c6d5f3685138f06d34651e6d34b42ec6d54fe6f6
  lua_language_server_platform=linux-x64
  lua_language_server_sha256=93ad326b10f6c00911dd8c450fa098332dbd8f9f45d1052f5636a2d54479b947
  ;;
aarch64)
  shfmt_platform=linux_arm64
  shfmt_sha256=5f2db09dae91fca848f7adbdd014632e921a383863a2ad7e0450ad3aba0c6489
  shellcheck_sha256=68a8133197a50beb8803f8d42f9908d1af1c5540d4bb05fdfca8c1fa47decefc
  lua_language_server_platform=linux-arm64
  lua_language_server_sha256=17b8e401a874440adeb649e5024c364f2bb9d15156c74a40e56d1ae9a1b2e4f2
  ;;
*)
  echo "unsupported machine: ${machine}" >&2
  exit 1
  ;;
esac

download=$(mktemp -d)
trap 'rm -rf "$download"' EXIT

curl -fsSL --max-time 300 -o "${download}/shfmt" \
  "https://github.com/mvdan/sh/releases/download/${shfmt_version}/shfmt_${shfmt_version}_${shfmt_platform}"
curl -fsSL --max-time 300 -o "${download}/shellcheck.tar.gz" \
  "https://github.com/koalaman/shellcheck/releases/download/${shellcheck_version}/shellcheck-${shellcheck_version}.linux.${machine}.tar.gz"
curl -fsSL --max-time 300 -o "${download}/lua-language-server.tar.gz" \
  "https://github.com/LuaLS/lua-language-server/releases/download/${lua_language_server_version}/lua-language-server-${lua_language_server_version}-${lua_language_server_platform}.tar.gz"
sha256sum -c - <<EOF
${shfmt_sha256}  ${download}/shfmt
${shellcheck_sha256}  ${download}/shellcheck.tar.gz
${lua_language_server_sha256}  ${download}/lua-language-server.tar.gz
EOF

mkdir -p "${prefix}/bin"
install -m 755 "${download}/shfmt" "${prefix}/bin/shfmt"
tar -xzf "${download}/shellcheck.tar.gz" --strip-components=1 -C "${prefix}/bin" \
  "shellcheck-${shellcheck_version}/shellcheck"
mkdir -p "${prefix}/share/lua-language-server"
tar -xzf "${download}/lua-language-server.tar.gz" -C "${prefix}/share/lua-language-server"
ln -sf "${prefix}/share/lua-language-server/bin/lua-language-server" "${prefix}/bin/lua-language-server"
shfmt_installed=$("${prefix}/bin/shfmt" --version)
echo "shfmt ${shfmt_installed}"
"${prefix}/bin/shellcheck" --version
lua_language_server_installed=$("${prefix}/bin/lua-language-server" --version)
echo "lua-language-server ${lua_language_server_installed}"
