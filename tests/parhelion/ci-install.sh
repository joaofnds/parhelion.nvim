#!/usr/bin/env bash
# Installs the Neovim, tree-sitter and fzf the suite runs with, and the shfmt, ShellCheck and lua-language-server the
# format check and the lint run with, under ~/.local, and prints the versions of Neovim, shfmt, ShellCheck and
# lua-language-server it installed.
# PARHELION_NEOVIM=nightly installs Neovim's nightly build in place of the pinned release, unchecked, since Neovim
# publishes no checksum for it. Exits 2 when PARHELION_NEOVIM names any other version.
set -euo pipefail
pinned_neovim=v0.12.6
neovim_version=${PARHELION_NEOVIM:-${pinned_neovim}}
if [[ "${neovim_version}" != "${pinned_neovim}" ]] && [[ "${neovim_version}" != nightly ]]; then
  printf 'PARHELION_NEOVIM must be %s or nightly, not "%s"\n' "${pinned_neovim}" "${neovim_version}" >&2
  exit 2
fi

tree_sitter_version=v0.26.11
fzf_version=0.74.5
shfmt_version=v3.14.1
shellcheck_version=v0.11.0
lua_language_server_version=3.19.2
prefix=${HOME}/.local

machine=$(uname -m)
case "${machine}" in
x86_64)
  neovim_platform=linux-x86_64
  neovim_sha256=474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87
  tree_sitter_platform=linux-x64
  tree_sitter_sha256=8dac3c89bb632eece700ea7a261ad963b251f2228c4aef3b58458ebea8dbe4eb
  fzf_platform=linux_amd64
  fzf_sha256=d47d7f882972c7d674dbbba998ffa4116e68379616ffac7695d0671e9a722c5f
  shfmt_platform=linux_amd64
  shfmt_sha256=76e77641faa025814b77f153b29796b8e6fa2fca03e0c76a691608b86c7ea7bf
  shellcheck_sha256=b7af85e41cc99489dcc21d66c6d5f3685138f06d34651e6d34b42ec6d54fe6f6
  lua_language_server_platform=linux-x64
  lua_language_server_sha256=93ad326b10f6c00911dd8c450fa098332dbd8f9f45d1052f5636a2d54479b947
  ;;
aarch64)
  neovim_platform=linux-arm64
  neovim_sha256=8f1f64a0bdb97247034038c3823c6cbad5bdf9ecd5751b85494b71c3ee04c815
  tree_sitter_platform=linux-arm64
  tree_sitter_sha256=e47dd59bf2f21ad7c15771546a724464ee3c008a60fbb61c6860bd19a44b3060
  fzf_platform=linux_arm64
  fzf_sha256=cf058001da21724a469b714a29cf4aab9cbe860d218a0d6c1b5b661efad7784c
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

curl -fsSL --max-time 300 -o "${download}/nvim.tar.gz" \
  "https://github.com/neovim/neovim/releases/download/${neovim_version}/nvim-${neovim_platform}.tar.gz"
curl -fsSL --max-time 300 -o "${download}/tree-sitter.gz" \
  "https://github.com/tree-sitter/tree-sitter/releases/download/${tree_sitter_version}/tree-sitter-${tree_sitter_platform}.gz"
curl -fsSL --max-time 300 -o "${download}/fzf.tar.gz" \
  "https://github.com/junegunn/fzf/releases/download/v${fzf_version}/fzf-${fzf_version}-${fzf_platform}.tar.gz"
curl -fsSL --max-time 300 -o "${download}/shfmt" \
  "https://github.com/mvdan/sh/releases/download/${shfmt_version}/shfmt_${shfmt_version}_${shfmt_platform}"
curl -fsSL --max-time 300 -o "${download}/shellcheck.tar.gz" \
  "https://github.com/koalaman/shellcheck/releases/download/${shellcheck_version}/shellcheck-${shellcheck_version}.linux.${machine}.tar.gz"
curl -fsSL --max-time 300 -o "${download}/lua-language-server.tar.gz" \
  "https://github.com/LuaLS/lua-language-server/releases/download/${lua_language_server_version}/lua-language-server-${lua_language_server_version}-${lua_language_server_platform}.tar.gz"
sha256sum -c - <<EOF
${tree_sitter_sha256}  ${download}/tree-sitter.gz
${fzf_sha256}  ${download}/fzf.tar.gz
${shfmt_sha256}  ${download}/shfmt
${shellcheck_sha256}  ${download}/shellcheck.tar.gz
${lua_language_server_sha256}  ${download}/lua-language-server.tar.gz
EOF
if [[ "${neovim_version}" != nightly ]]; then
  sha256sum -c - <<<"${neovim_sha256}  ${download}/nvim.tar.gz"
fi

mkdir -p "${prefix}/bin"
tar -xzf "${download}/nvim.tar.gz" --strip-components=1 -C "${prefix}"
gunzip -c "${download}/tree-sitter.gz" >"${prefix}/bin/tree-sitter"
chmod +x "${prefix}/bin/tree-sitter"
tar -xzf "${download}/fzf.tar.gz" -C "${prefix}/bin" fzf
install -m 755 "${download}/shfmt" "${prefix}/bin/shfmt"
tar -xzf "${download}/shellcheck.tar.gz" --strip-components=1 -C "${prefix}/bin" \
  "shellcheck-${shellcheck_version}/shellcheck"
mkdir -p "${prefix}/share/lua-language-server"
tar -xzf "${download}/lua-language-server.tar.gz" -C "${prefix}/share/lua-language-server"
ln -sf "${prefix}/share/lua-language-server/bin/lua-language-server" "${prefix}/bin/lua-language-server"
"${prefix}/bin/nvim" --version
shfmt_installed=$("${prefix}/bin/shfmt" --version)
echo "shfmt ${shfmt_installed}"
"${prefix}/bin/shellcheck" --version
lua_language_server_installed=$("${prefix}/bin/lua-language-server" --version)
echo "lua-language-server ${lua_language_server_installed}"
