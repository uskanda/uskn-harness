---
name: sync-base
description: Bring the latest remote integration branch into the current branch. Tries a fast-forward first and falls back to a --no-ff merge without asking; never rebases. Use when the user wants the current branch updated with the base branch. Optional argument: a different base branch.
allowed-tools: Bash
---

# Merge the remote base branch into the current branch

## Context

Base branch: `$ARGUMENTS` when given, otherwise the integration branch from the `<repo-context>` block injected at session start. If the block is absent, run
`"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/session-start.sh" --json`.

## Steps

1. **Refuse to run on a dirty tree.** `git status --porcelain`. If anything is listed, print the list under the heading below and stop without running anything else.
2. **Fetch.** `git fetch origin <base>`.
3. **Fast-forward first.** `git merge --ff-only origin/<base>`. On success, report "fast-forwarded" and go to step 5.
4. **Otherwise merge without asking.** `git merge --no-ff origin/<base>`. Do not offer a rebase and do not ask which strategy to use. On conflicts, leave the merge in progress (no `git merge --abort`), list the conflicting files (`git diff --name-only --diff-filter=U`), and hand over to the user.
5. **Report.** `git log --oneline -5`, and state whether it was a fast-forward or a merge commit.

## Message when the tree is dirty

```
There are uncommitted changes:

- <file>
- <file>

Commit or stash them first, then run again. Nothing was done.
```

Write it in the language of the user or repository instructions (default Japanese).
