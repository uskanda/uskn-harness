---
name: switch-base
description: Switch to the integration branch and update it to the latest remote state. Use when the user wants to go back to the base branch before starting new work. Optional argument: a different branch to switch to.
allowed-tools: Bash
---

# Switch to the base branch and update it

## Context

Target branch: `$ARGUMENTS` when given, otherwise the integration branch from the `<repo-context>` block injected at session start. If the block is absent, run
`"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/session-start.sh" --json`.

## Steps

1. **Refuse to run on a dirty tree.** `git status --porcelain`. If anything is listed, show the list (same message as `sync-base`) and stop.
2. `git switch <target>` (or `git checkout <target>` on old git).
3. `git pull --ff-only`. If the pull cannot fast-forward, stop and report; do not merge or rebase on the base branch.
4. Report `git log --oneline -5`.
