# Contributing

`make test` runs the suite, which needs the tools [DESIGN.md](DESIGN.md#the-test-suite) lists and fetches the pinned
plugins and parsers it compares. `make format-check` and `make lint` run the formatting, shell and type checks CI runs,
with the StyLua, shfmt, ShellCheck and lua-language-server on your `PATH`. CI's versions are pinned in
`tests/parhelion/ci-install-lint.sh` and, for StyLua, in `.github/workflows/parhelion.yml`.

After a change to the base tables, `refinement.lua` or `chrome.lua`, run `make build` and commit the built tables and
terminal themes it writes with the change. The suite fails until they match their sources.

[DESIGN.md](DESIGN.md) says how a load works, how to add a plugin and what the suite compares, and
[GLOSSARY.md](GLOSSARY.md) defines the terms they use. Commit subjects follow Conventional Commits, as DESIGN.md says,
and `make lintcommit` checks the commits on `HEAD` that `origin/main` lacks.

Report a bug with the bug report form. The reproduction it asks for, which `nvim --clean -u repro.lua` runs, is where a
fix starts.
