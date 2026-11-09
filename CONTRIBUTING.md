# Contributing

`make test` runs the suite. The README's [Tests](README.md#tests) section names the other checks, and
[The test suite](DESIGN.md#the-test-suite) in DESIGN.md says what the suite needs, what it compares and how CI runs it,
commit subjects included.

A load reads the tables `make build` writes, so a change to what they are built from needs `make build` and a commit of
what it writes. [How a load works](DESIGN.md#how-a-load-works) names those sources, and the suite fails while the
written files are stale. [Adding a plugin](DESIGN.md#adding-a-plugin) says where a plugin's groups go.

A change a user can see goes in [CHANGELOG.md](CHANGELOG.md) under its Unreleased heading, and
[GLOSSARY.md](GLOSSARY.md) defines the terms these documents use.

Report a bug with the [bug report form](https://github.com/joaofnds/parhelion.nvim/issues/new?template=bug_report.yml).
The reproduction it asks for is where a fix starts.
