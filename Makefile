SHELL := bash
RANGE = origin/main..HEAD
SHELL_SCRIPTS = $(shell git ls-files -z | xargs -0 shfmt -f)

.PHONY: build test bench format-check lint lintcommit

build:
	nvim --headless --clean --cmd "set rtp^=." -c "lua require('parhelion.build').write()" -c "qa!"

test:
	tests/parhelion/run.sh

bench:
	tests/parhelion/bench.sh

format-check:
	stylua --check --config-path=stylua.toml .
	shfmt --diff $(SHELL_SCRIPTS)

lint:
	shellcheck $(SHELL_SCRIPTS)

lintcommit:
	set -o pipefail; git log --no-merges --format='%h %s' $(RANGE) | tests/parhelion/lintcommit.sh
