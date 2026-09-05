# uskn-harness

Shared harness for agentic coding across the owner's personal products: skills, hooks, templates, and the
installer that distributes them. This file is the entry point; it stays short and points elsewhere.

## Layout

| Path | What lives there |
|---|---|
| `skills/<name>/SKILL.md` | Canonical skills. Agent Skills spec (agentskills.io), English, under 500 lines |
| `templates/repo/` , `templates/user/` , `templates/chezmoi/` | Files installed into product repos, into the user layer, and the dotfiles bootstrap |
| `schemas/` | OpenSpec schema `uskn` (grilling artifact ahead of proposal) |
| `plugins/uskn-harness/` | Claude Code plugin: the hook bodies (bash + jq), `hooks.json`, and their bats tests. No skills |
| `deps.json` | Pinned sources of every external skill, CLI, and runtime |
| `docs/adr/` | Architecture decisions. Start with ADR-0001 |
| `docs/handoffs/` | Instructions for another session: onboarding another repository (mirrored in its draft PR), or picking up work here |
| `openspec/` | This repository's own specs and changes (dogfooding) |

## How work happens here

1. A change starts with `/spec <idea>`: the grilling interview, its record (`grilling.md`), then the OpenSpec
   artifacts. Writing proposal / design / tasks / specs without `grilling.md` is denied by a hook.
2. Implement through `/opsx:apply`. Scripts get bats tests first (TDD); skills get a worked example in their body.
3. `make verify` must pass before a change is called done. Hooks call the same target; CI runs it with
   `VERIFY_STRICT=1`, where a missing tool fails instead of skipping.
4. Archive with `/opsx:archive`. The archive is the decision history; do not delete it.

## Language

Skills, hook code, templates, and this file: English. Chat replies, commits, pull requests, ADRs, and OpenSpec
artifacts: Japanese.

## Hard constraints

- Never edit a project outside this repository. A change another repository needs becomes either a pull request
  made from a fresh clone in the scratchpad, or a handoff document in `docs/handoffs/`. Live working trees such as
  `~/dotfiles` and `~/repos/*` stay untouched until the owner says otherwise.
- External skills are referenced, pinned in `deps.json`, and never copied, except the entries listed under
  `forks`, which carry their upstream license.
- A product repository carries at most `AGENTS.md`, `CLAUDE.md`, `openspec/`, `DESIGN.md`, `PRODUCT.md`, and a
  `verify` target. That list is an upper bound, not a checklist: `DESIGN.md` and `PRODUCT.md` belong only to a
  repository that has a user interface. Everything else arrives through the installer.
- Every guide (skill, rule) that matters gets a sensor (hook, lint, test). Prefer computational sensors.

## References

- Architecture and every decision so far: `docs/adr/0001-harness-architecture.md`
- Research behind the decisions: `docs/proposal-2026-09.md`
