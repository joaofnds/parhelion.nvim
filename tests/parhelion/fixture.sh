#!/usr/bin/env bash
# Builds a repository whose status, commit, and diff views show every kind of change.
# History comes from a fast-import stream, which states its own authorship.
set -euo pipefail
dir=$1
rm -rf "${dir}"
mkdir -p "${dir}"
cd "${dir}"
git init -q -b main

blob() { printf 'data %d\n%s\n' "${#1}" "$1"; }
commit() { # mark epoch message file content
  printf 'commit refs/heads/main\nmark :%s\n' "$1"
  printf 'author Ada Example <ada@example.com> %s +0000\n' "$2"
  printf 'committer Ada Example <ada@example.com> %s +0000\n' "$2"
  blob "$3"
  printf 'M 100644 inline %s\n' "$4"
  blob "$5"
  printf '\n'
}

app_v1=$'local M = {}\n\nfunction M.add(a, b)\n\treturn a + b\nend\n\nfunction M.sub(a, b)\n\treturn a - b\nend\n\nreturn M'
app_v2=$'local M = { version = 2 }\n\nfunction M.add(a, b)\n\treturn a + b\nend\n\nfunction M.sub(a, b)\n\treturn a - b\nend\n\nreturn M'
view_v1=$'export function View() {\n  return <div className="old">hello</div>;\n}'
notes_v1=$'first line\nsecond line\nthird line'
gone_v1=$'to be removed'

{
  commit 1 1577836800 "add application module" src/app.lua "${app_v1}"
  commit 2 1577923200 "add view component" src/view.tsx "${view_v1}"
  commit 3 1578009600 "add notes" notes.md "${notes_v1}"
  commit 4 1578096000 "add file that goes away" gone.txt "${gone_v1}"
  commit 5 1578182400 $'bump application version\n\nThe module now reports the version it exports.' src/app.lua "${app_v2}"
  printf 'reset refs/remotes/origin/main\nfrom :4\n\n'
  printf 'reset refs/tags/v1.0.0\nfrom :3\n\n'
} | git fast-import --quiet
git config remote.origin.url https://example.invalid/fixture.git
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git config branch.main.remote origin
git config branch.main.merge refs/heads/main
git checkout -q main

printf 'export function View() {\n  return <div className="new">hello there</div>;\n}\n' >src/view.tsx
git add src/view.tsx
printf 'body { color: red; }\n' >new.css
git add new.css
rm gone.txt
{
  printf 'local M = { version = 2 }\n\nfunction M.add(a, b)\n\tlocal sum = a + b\n\treturn sum\nend\n\n'
  printf 'function M.mul(a, b)\n\treturn a * b\nend\n\nreturn M\n'
} >src/app.lua
printf 'first line\nsecond line changed\nthird line\nfourth line\n' >notes.md
printf 'scratch\n' >untracked.txt
