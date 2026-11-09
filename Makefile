SHELL := bash
RANGE ?= origin/main..HEAD

.PHONY: build test bench format-check lintcommit

build:
	nvim --headless --clean --cmd "set rtp^=." -c "lua require('parhelion.build').write()" -c "qa!"

test:
	tests/parhelion/run.sh

bench:
	tests/parhelion/bench.sh

format-check:
	stylua --check --config-path=stylua.toml .

lintcommit:
	set -o pipefail; git log --no-merges --format='%h %s' $(RANGE) | tests/parhelion/lintcommit.sh
