# uskn-harness

Shared harness for agentic coding across the owner's personal products: skills, hooks, templates, and the
installer that distributes them.

## Layout

| Path | What lives there |
|---|---|
| `skills/<name>/SKILL.md` | Canonical skills. Agent Skills spec (agentskills.io), English, under 500 lines |
| `templates/repo/` , `templates/user/` , `templates/chezmoi/` | Files installed into product repos, into the user layer, and the dotfiles bootstrap. English |
| `schemas/` | OpenSpec schema `uskn` (grilling artifact ahead of proposal) |
| `plugins/uskn-harness/` | Claude Code plugin: the hook bodies (bash + jq), `hooks.json`, their bats tests, and the short commands skills call. No skills |
| `bin/` | The installer `uskn-harness` (sync, doctor, onboard-check), the loop runner `uskn-loop`, and the bats tests for them and for skill frontmatter |
| `loop/` | What `uskn-loop` reads: shared functions, the implementer and auditor prompts, the verdict schema, the limits (ADR-0006) |
| `deps.json` | Pinned sources of every external skill, CLI, and runtime |
| `docs/adr/` | Architecture decisions. Start with ADR-0001 |
| `openspec/` | This repository's own specs and changes (dogfooding) |

## How work happens here

- Scripts get bats tests first; skills get a worked example in their body.
- Scripts and tests run on Linux and on macOS, where bats and the hooks get `/bin/bash` 3.2 and BSD tools. End a
  `[[ ]]` statement in a test with `|| false`, use `sed -E` / `grep -E` for alternation, and list trees with the
  `listing` helper instead of `find -printf`. `bin/tests/bats-portability.bats` checks these.
- CI runs `make verify` with `VERIFY_STRICT=1`, where a missing tool fails instead of skipping.

## Branch model

`main` has no branch protection on GitHub. The other keys are detected.

```yaml
protected: none
```

## Hard constraints

- External skills are referenced and pinned in `deps.json`. Only the entries under `forks` are copied, each with its
  upstream license.
- A product repository carries only what the conventions call for: `AGENTS.md`, `openspec/` (with
  `glossary.yml`), a `verify` target, and `DESIGN.md` plus `PRODUCT.md` when it has a user interface. The list is
  today's contents, not a cap. Everything else arrives through the installer. `AGENTS.md` is the only instruction
  file, here too: no `CLAUDE.md` (ADR-0003).
- Every guide (skill, rule) that matters gets a sensor (hook, lint, test). Prefer computational sensors.
- Names come from the code, `openspec/glossary.yml`, or a document you consulted. A new term goes into the
  glossary before it goes into prose. One concept, one term. A backticked name must exist.

## References

- Architecture and every decision so far: `docs/adr/0001-harness-architecture.md`
- Research behind the decisions: `docs/proposal-2026-09.md`
