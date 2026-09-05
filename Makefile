# Verification entry point. Harness hooks look for `make verify` first (see ADR-0001, §12.1).
# Every check skips gracefully when its tool is absent, so this target is safe to run anywhere.
SHELL := /usr/bin/env bash
SHIMS := $(HOME)/.local/share/mise/shims
export PATH := $(SHIMS):$(HOME)/.local/bin:$(PATH)

.PHONY: verify verify-openspec verify-shell verify-skills

verify: verify-openspec verify-shell verify-skills ## Run every check that applies to this repo
	@echo "verify: ok"

verify-openspec:
	@if command -v openspec >/dev/null && [ -d openspec ]; then \
	  echo "[openspec] validate --all"; openspec validate --all --no-interactive || exit 1; \
	else echo "[openspec] skipped (cli or openspec/ missing)"; fi

verify-shell:
	@files=$$(find hooks/scripts bin -type f \( -name '*.sh' -o -perm -u+x \) 2>/dev/null); \
	if [ -z "$$files" ]; then echo "[shell] skipped (no scripts yet)"; \
	elif command -v shellcheck >/dev/null; then echo "[shell] shellcheck"; shellcheck $$files; \
	else echo "[shell] bash -n only (shellcheck not installed)"; for f in $$files; do bash -n "$$f" || exit 1; done; fi; \
	if command -v bats >/dev/null && [ -d hooks/tests ]; then echo "[shell] bats"; bats hooks/tests; fi

verify-skills:
	@dirs=$$(find skills -mindepth 1 -maxdepth 2 -name SKILL.md -exec dirname {} \; 2>/dev/null); \
	if [ -z "$$dirs" ]; then echo "[skills] skipped (no skills yet)"; \
	elif command -v skills-ref >/dev/null; then for d in $$dirs; do skills-ref validate "$$d" || exit 1; done; \
	else echo "[skills] frontmatter check (skills-ref not installed)"; \
	  for d in $$dirs; do head -1 "$$d/SKILL.md" | grep -q '^---$$' || { echo "missing frontmatter: $$d"; exit 1; }; \
	  grep -qE '^name: ' "$$d/SKILL.md" || { echo "missing name: $$d"; exit 1; }; \
	  grep -qE '^description: ' "$$d/SKILL.md" || { echo "missing description: $$d"; exit 1; }; done; fi
