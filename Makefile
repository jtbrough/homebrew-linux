.PHONY: all lint patch diff-check build test clean

SHELL := /bin/bash

all: lint diff-check test

lint:
	@echo "==> Running ShellCheck on scripts..."
	shellcheck -S style install.sh scripts/test.sh
	@echo "✔ ShellCheck passed with 0 findings."

patch:
	@echo "==> Regenerating patches/opt-homebrew-prefix.patch..."
	diff -u patches/install.sh.orig install.sh > patches/opt-homebrew-prefix.patch || true
	@echo "✔ Patch regenerated."

diff-check:
	@echo "==> Checking patch consistency..."
	@diff -u -I '^--- ' -I '^\+\+\+ ' patches/opt-homebrew-prefix.patch <(diff -u patches/install.sh.orig install.sh || true) || \
		(echo "✘ Error: patches/opt-homebrew-prefix.patch is out of date. Run 'make patch'." && exit 1)
	@echo "✔ Patch is synchronized with install.sh."

build:
	@echo "==> Building container testbed..."
	podman build -t homebrew-linux-opt:test -f docker/Dockerfile .

test:
	@echo "==> Running container test matrix..."
	./scripts/test.sh
