SHELL := bash
RANGE = origin/main..HEAD
SHELL_SCRIPTS = $(shell git ls-files -z | xargs -0 shfmt -f)

.PHONY: build test bench format-check lint lintcommit review

build:
	nvim --headless --clean --cmd "set rtp^=." -c "lua require('parhelion.build').write()" \
		-c "if v:errmsg != '' | cquit | endif" -c "qa!"

test:
	tests/parhelion/run.sh

bench:
	tests/parhelion/bench.sh

format-check:
	stylua --check --config-path=stylua.toml .
	shfmt --indent=2 --diff $(SHELL_SCRIPTS)

lint:
	shellcheck $(SHELL_SCRIPTS)
	VIMRUNTIME="$$(nvim --clean --headless +'lua io.write(vim.env.VIMRUNTIME)' +q)" \
		lua-language-server --check=. --checklevel=Hint --configpath=.luarc.json --check_format=pretty

lintcommit:
	set -o pipefail; git log --no-merges --format='%h %s' $(RANGE) | tests/parhelion/lintcommit.sh

review:
	tests/parhelion/review/review.sh "$(EXPERIMENTS)" $(OUT)
