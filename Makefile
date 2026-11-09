.PHONY: test bench format-check

test:
	tests/parhelion/run.sh

bench:
	tests/parhelion/bench.sh

format-check:
	stylua --check --config-path=stylua.toml .
