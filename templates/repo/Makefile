# Verification entry point. `make verify` is the convention the harness looks for: the Stop hook `verify-gate`
# and the `verify` skill both call this target, and nothing is called done until it passes.
# Keep every check guarded so the target still runs where a tool is missing.
SHELL := /usr/bin/env bash

.PHONY: verify verify-lint verify-types verify-test

verify: verify-lint verify-types verify-test ## Run every check that applies to this repository
	@echo "verify: ok"

verify-lint:
	@# Replace with this repository's linter, e.g. npx expo lint / npx eslint . / ruff check .
	@if command -v node >/dev/null; then echo "[lint] <command>"; else echo "[lint] skipped (node missing)"; fi

verify-types:
	@# Replace with this repository's type check, e.g. npx tsc --noEmit
	@if [ -f tsconfig.json ]; then echo "[types] <command>"; else echo "[types] skipped (no tsconfig.json)"; fi

verify-test:
	@# Replace with this repository's tests. When there are none, say so here rather than pretending.
	@echo "[test] skipped (no test suite yet)"
