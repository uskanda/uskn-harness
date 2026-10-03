# Verification entry point. Harness hooks look for `make verify` first (see ADR-0001, §12.1).
# Every check skips gracefully when its tool is absent, so this target is safe to run anywhere.
SHELL := /usr/bin/env bash
SHIMS := $(HOME)/.local/share/mise/shims
export PATH := $(SHIMS):$(HOME)/.local/bin:$(PATH)

# VERIFY_STRICT=1 (CI): a check whose tool is missing fails instead of being skipped.
VERIFY_STRICT ?= 0
# $(call skip,<message>): report a check that cannot run here; under VERIFY_STRICT=1 that is a failure.
skip = if [ "$(VERIFY_STRICT)" = 1 ]; then echo "$(1) -- VERIFY_STRICT=1: this check is required" >&2; exit 1; else echo "$(1)"; fi

SCRIPT_DIRS := plugins/uskn-harness/hooks/scripts plugins/uskn-harness/bin bin
TEST_DIRS   := plugins/uskn-harness/hooks/tests bin/tests
SKILLS_DIR  ?= skills

# Every SKILL.md frontmatter must be real YAML: a `key: value` inside a plain scalar ("Argument: x") parses in
# Claude Code but not in other agents or skills-ref. Arguments: the skill directories. Run by verify-skills.
define SKILL_FRONTMATTER_PY
import os, sys, yaml
bad = 0
def fail(path, why):
    global bad
    bad += 1
    print(f"{path}: {why}")
for d in sys.argv[1:]:
    path = os.path.join(d, "SKILL.md")
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    if lines[0].strip() != "---":
        fail(path, "no frontmatter (the first line is not ---)")
        continue
    try:
        end = [ln.strip() for ln in lines].index("---", 1)
    except ValueError:
        fail(path, "the frontmatter is not closed by a --- line")
        continue
    try:
        meta = yaml.safe_load("\n".join(lines[1:end]))
    except yaml.YAMLError as err:
        fail(path, "the frontmatter is not valid YAML: " + " ".join(str(err).split()))
        continue
    if not isinstance(meta, dict):
        fail(path, "the frontmatter is not a mapping")
        continue
    if meta.get("name") != os.path.basename(os.path.normpath(d)):
        fail(path, f"name {meta.get('name')!r} differs from the directory name")
    desc = meta.get("description")
    if not isinstance(desc, str) or not desc.strip():
        fail(path, "description is missing or empty")
sys.exit(1 if bad else 0)
endef
export SKILL_FRONTMATTER_PY

.PHONY: verify verify-openspec verify-shell verify-skills verify-plugin verify-textlint verify-design verify-terms \
        verify-fast verify-fast-plan

# Japanese prose that is still alive: README, ADRs, main specs, active changes. docs/proposal-2026-09.md and
# openspec/changes/archive/ are records and stay as written.
DOCS_JA := README.md docs/setup-new-machine.md $(wildcard docs/adr/*.md) \
           $(shell find openspec/specs -name '*.md' 2>/dev/null) \
           $(shell find openspec/changes -mindepth 2 -name '*.md' -not -path 'openspec/changes/archive/*' 2>/dev/null)

# Prose the terminology guard checks: the Japanese set plus the English documents agents read.
DOCS_TERMS := $(DOCS_JA) AGENTS.md plugins/uskn-harness/README.md $(shell find skills -name 'SKILL.md' 2>/dev/null)
TERMS_CHECK := plugins/uskn-harness/hooks/scripts/terms-check.sh

verify: verify-openspec verify-shell verify-skills verify-plugin verify-textlint verify-design verify-terms ## Run every check that applies to this repo
	@echo "verify: ok"

verify-openspec:
	@if command -v openspec >/dev/null && [ -d openspec ]; then \
	  echo "[openspec] validate --all --strict"; openspec validate --all --strict --no-interactive || exit 1; \
	  if openspec schema which uskn >/dev/null 2>&1; then echo "[openspec] schema validate uskn"; openspec schema validate uskn || exit 1; \
	  else $(call skip,[openspec] schema uskn not resolvable here (run uskn-harness sync); skipped); fi; \
	else $(call skip,[openspec] skipped (cli or openspec/ missing)); fi

verify-shell:
	@files=$$(find $(SCRIPT_DIRS) -type f \( -name '*.sh' -o -perm -u+x \) 2>/dev/null | grep -v '/tests/' | grep -v '/lib/' || true); \
	if [ -z "$$files" ]; then echo "[shell] skipped (no scripts yet)"; \
	elif command -v shellcheck >/dev/null; then echo "[shell] shellcheck"; shellcheck -x -P SCRIPTDIR $$files; \
	else $(call skip,[shell] bash -n only (shellcheck not installed)); for f in $$files; do bash -n "$$f" || exit 1; done; fi; \
	tests=$$(for d in $(TEST_DIRS); do [ -d "$$d" ] && echo "$$d"; done); \
	if [ -n "$$tests" ] && command -v bats >/dev/null; then echo "[shell] bats $$tests"; bats $$tests || exit 1; \
	elif [ -n "$$tests" ]; then $(call skip,[shell] bats not installed; tests skipped); fi

verify-skills:
	@dirs=$$(find $(SKILLS_DIR) -mindepth 1 -maxdepth 3 -name SKILL.md -exec dirname {} \; 2>/dev/null); \
	if [ -z "$$dirs" ]; then echo "[skills] skipped (no skills yet)"; exit 0; fi; \
	if python3 -c 'import yaml' >/dev/null 2>&1; then echo "[skills] frontmatter parsed as YAML"; \
	  python3 -c "$$SKILL_FRONTMATTER_PY" $$dirs || exit 1; \
	else $(call skip,[skills] YAML parse skipped (python3 with PyYAML not available)); fi; \
	if command -v skills-ref >/dev/null; then for d in $$dirs; do skills-ref validate "$$d" || exit 1; done; \
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
	else $(call skip,[plugin] skipped (claude cli or plugin dir missing)); fi

verify-textlint:
	@if command -v textlint >/dev/null; then echo "[textlint] $(words $(DOCS_JA)) ja documents"; \
	  textlint --config skills/ja-writing/textlintrc.json $(DOCS_JA) || exit 1; \
	else $(call skip,[textlint] skipped (textlint not installed; run uskn-harness sync)); fi

verify-design:
	@if command -v designmd >/dev/null; then echo "[design.md] lint templates/repo/DESIGN.md"; \
	  if out=$$(designmd lint templates/repo/DESIGN.md); then echo "$$out" | jq -c '.summary' 2>/dev/null || true; \
	  else echo "$$out"; exit 1; fi; \
	else $(call skip,[design.md] skipped (designmd not installed; run uskn-harness sync)); fi

verify-terms:
	@if [ -x "$(TERMS_CHECK)" ]; then echo "[terms] $(words $(DOCS_TERMS)) documents"; \
	  VERIFY_STRICT=$(VERIFY_STRICT) "$(TERMS_CHECK)" $(DOCS_TERMS) || exit 1; \
	else $(call skip,[terms] skipped (terms-check.sh missing)); fi

# ---- verify-fast: what the verify gate runs at Stop (openspec: verify-fast). The checks of `verify`, narrowed to the
# files that changed since VERIFY_BASE plus untracked files; the full `verify` runs in CI and in archive-push.
# VERIFY_BASE: where HEAD left the remote (the upstream, origin/HEAD, origin/main, origin/master), else HEAD.
VERIFY_BASE ?= $(shell for r in '@{upstream}' origin/HEAD origin/main origin/master; do git merge-base HEAD "$$r" 2>/dev/null && exit 0; done; echo HEAD)
# CHANGED is computed once, on first use (the $(eval) memo), so no other target runs git for it. Given on the make
# command line, it replaces the git answer: `make verify-fast-plan CHANGED="a.md b.sh"` (the tests do this).
CHANGED = $(eval CHANGED := $$(sort $$(shell git diff --name-only --diff-filter=d $$(VERIFY_BASE) -- 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)))$(CHANGED)
SCRIPTS = $(shell find $(SCRIPT_DIRS) -type f \( -name '*.sh' -o -perm -u+x \) 2>/dev/null | grep -v '/tests/' | grep -v '/lib/')
HOOK_SCRIPTS := plugins/uskn-harness/hooks/scripts
HOOK_TESTS   := plugins/uskn-harness/hooks/tests
# What to check. A shared input (the glossary, the textlint config, the hooks' lib) widens its check to everything.
FAST_TEXTLINT = $(if $(filter skills/ja-writing/textlintrc.json skills/ja-writing/prh.yml,$(CHANGED)),$(DOCS_JA),$(filter $(CHANGED),$(DOCS_JA)))
FAST_TERMS    = $(if $(filter openspec/glossary.yml openspec/known-names.txt skills/ja-writing/common-words.txt,$(CHANGED)),$(DOCS_TERMS),$(filter $(CHANGED),$(DOCS_TERMS)))
FAST_SHELL    = $(if $(filter $(HOOK_SCRIPTS)/lib/%,$(CHANGED)),$(SCRIPTS),$(filter $(CHANGED),$(SCRIPTS)))
# The bats files a change touches: a changed test itself; hooks/scripts/<name>.sh -> hooks/tests/<name>.bats; the
# lib and the fixtures -> every hook test; bin/uskn-loop and loop/ -> bin/tests/uskn-loop.bats; the rest by name.
# bin/tests/skill-*.bats look at every skill.
FAST_BATS     = $(sort $(wildcard $(filter %.bats,$(CHANGED)) \
  $(patsubst $(HOOK_SCRIPTS)/%.sh,$(HOOK_TESTS)/%.bats,$(filter $(HOOK_SCRIPTS)/%.sh,$(CHANGED))) \
  $(if $(filter $(HOOK_SCRIPTS)/lib/% $(HOOK_TESTS)/fixtures/%,$(CHANGED)),$(HOOK_TESTS)/*.bats) \
  $(if $(filter plugins/uskn-harness/hooks/hooks.json,$(CHANGED)),$(HOOK_TESTS)/hooks-json.bats) \
  $(if $(filter plugins/uskn-harness/bin/%,$(CHANGED)),$(HOOK_TESTS)/plugin-bin.bats) \
  $(if $(filter bin/uskn-harness,$(CHANGED)),bin/tests/uskn-harness.bats) \
  $(if $(filter bin/uskn-loop loop/%,$(CHANGED)),bin/tests/uskn-loop.bats) \
  $(if $(filter Makefile,$(CHANGED)),bin/tests/makefile.bats) \
  $(if $(filter skills/%,$(CHANGED)),bin/tests/skill-*.bats) \
  $(patsubst skills/%/SKILL.md,bin/tests/%-skill.bats,$(filter skills/%/SKILL.md,$(CHANGED)))))

verify-fast: ## Check only what changed since VERIFY_BASE (the verify gate runs this at Stop)
	@echo "[fast] $(words $(CHANGED)) file(s) changed since $(VERIFY_BASE)"
	@if [ -z "$(strip $(FAST_TEXTLINT)$(FAST_TERMS)$(FAST_SHELL)$(FAST_BATS))" ]; then echo "[fast] nothing to check"; fi
	@files="$(FAST_TEXTLINT)"; if [ -z "$$files" ]; then :; \
	elif command -v textlint >/dev/null; then echo "[textlint] $(words $(FAST_TEXTLINT)) ja document(s)"; \
	  textlint --config skills/ja-writing/textlintrc.json $$files || exit 1; \
	else $(call skip,[textlint] skipped (textlint not installed; run uskn-harness sync)); fi
	@files="$(FAST_TERMS)"; if [ -z "$$files" ]; then :; \
	elif [ -x "$(TERMS_CHECK)" ]; then echo "[terms] $(words $(FAST_TERMS)) document(s)"; \
	  VERIFY_STRICT=$(VERIFY_STRICT) "$(TERMS_CHECK)" $$files || exit 1; \
	else $(call skip,[terms] skipped (terms-check.sh missing)); fi
	@files="$(FAST_SHELL)"; if [ -z "$$files" ]; then :; \
	elif command -v shellcheck >/dev/null; then echo "[shell] shellcheck $(words $(FAST_SHELL)) script(s)"; \
	  shellcheck -x -P SCRIPTDIR $$files || exit 1; \
	else $(call skip,[shell] bash -n only (shellcheck not installed)); for f in $$files; do bash -n "$$f" || exit 1; done; fi
	@files="$(FAST_BATS)"; if [ -z "$$files" ]; then :; \
	elif command -v bats >/dev/null; then echo "[shell] bats $(words $(FAST_BATS)) file(s)"; bats $$files || exit 1; \
	else $(call skip,[shell] bats not installed; tests skipped); fi
	@echo "verify-fast: ok"

verify-fast-plan: ## Print what verify-fast would check, one "<check>: <files>" line each
	@echo "base: $(VERIFY_BASE)"
	@echo "changed: $(CHANGED)"
	@echo "textlint: $(FAST_TEXTLINT)"
	@echo "terms: $(FAST_TERMS)"
	@echo "shellcheck: $(FAST_SHELL)"
	@echo "bats: $(FAST_BATS)"
