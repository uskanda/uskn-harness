# Verification entry point. Harness hooks look for `make verify` first (see ADR-0001, §12.1).
# Every check skips gracefully when its tool is absent, so this target is safe to run anywhere.
SHELL := /usr/bin/env bash
SHIMS := $(HOME)/.local/share/mise/shims
export PATH := $(SHIMS):$(HOME)/.local/bin:$(PATH)

SCRIPT_DIRS := plugins/uskn-harness/hooks/scripts bin
TEST_DIRS   := plugins/uskn-harness/hooks/tests bin/tests

.PHONY: verify verify-openspec verify-shell verify-skills verify-plugin

verify: verify-openspec verify-shell verify-skills verify-plugin ## Run every check that applies to this repo
	@echo "verify: ok"

verify-openspec:
	@if command -v openspec >/dev/null && [ -d openspec ]; then \
	  echo "[openspec] validate --all --strict"; openspec validate --all --strict --no-interactive || exit 1; \
	  if openspec schema which uskn >/dev/null 2>&1; then echo "[openspec] schema validate uskn"; openspec schema validate uskn || exit 1; \
	  else echo "[openspec] schema uskn not resolvable here (run uskn-harness sync); skipped"; fi; \
	else echo "[openspec] skipped (cli or openspec/ missing)"; fi

verify-shell:
	@files=$$(find $(SCRIPT_DIRS) -type f \( -name '*.sh' -o -perm -u+x \) 2>/dev/null | grep -v '/tests/' | grep -v '/lib/' || true); \
	if [ -z "$$files" ]; then echo "[shell] skipped (no scripts yet)"; \
	elif command -v shellcheck >/dev/null; then echo "[shell] shellcheck"; shellcheck -x -P SCRIPTDIR $$files; \
	else echo "[shell] bash -n only (shellcheck not installed)"; for f in $$files; do bash -n "$$f" || exit 1; done; fi; \
	tests=$$(for d in $(TEST_DIRS); do [ -d "$$d" ] && echo "$$d"; done); \
	if [ -n "$$tests" ] && command -v bats >/dev/null; then echo "[shell] bats $$tests"; bats $$tests || exit 1; \
	elif [ -n "$$tests" ]; then echo "[shell] bats not installed; tests skipped"; fi

verify-skills:
	@dirs=$$(find skills -mindepth 1 -maxdepth 3 -name SKILL.md -exec dirname {} \; 2>/dev/null); \
	if [ -z "$$dirs" ]; then echo "[skills] skipped (no skills yet)"; \
	elif command -v skills-ref >/dev/null; then for d in $$dirs; do skills-ref validate "$$d" || exit 1; done; \
	else echo "[skills] frontmatter check (skills-ref not installed)"; \
	  for d in $$dirs; do head -1 "$$d/SKILL.md" | grep -q '^---$$' || { echo "missing frontmatter: $$d"; exit 1; }; \
	  n=$$(sed -n 's/^name: *//p' "$$d/SKILL.md" | head -1); [ "$$n" = "$$(basename "$$d")" ] || { echo "name/dir mismatch: $$d ($$n)"; exit 1; }; \
	  grep -qE '^description: ' "$$d/SKILL.md" || { echo "missing description: $$d"; exit 1; }; \
	  [ "$$(wc -l < "$$d/SKILL.md")" -le 500 ] || { echo "over 500 lines: $$d"; exit 1; }; done; \
	  names=$$(for d in $$dirs; do basename "$$d"; done | sort); dup=$$(echo "$$names" | uniq -d); \
	  [ -z "$$dup" ] || { echo "duplicate skill names: $$dup"; exit 1; }; fi

verify-plugin:
	@if command -v claude >/dev/null && [ -d plugins/uskn-harness ]; then \
	  echo "[plugin] claude plugin validate --strict"; claude plugin validate --strict plugins/uskn-harness || exit 1; \
	else echo "[plugin] skipped (claude cli or plugin dir missing)"; fi
