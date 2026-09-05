---
name: cleanup-merged
description: List local branches already merged into the remote integration branch and delete them after confirmation. Use for periodic branch cleanup. Optional argument: a different base branch to compare against.
allowed-tools: Bash, AskUserQuestion
---

# Delete local branches that are merged into the base branch

## Context

Base branch: `$ARGUMENTS` when given, otherwise the integration branch from the `<repo-context>` block injected at session start. If the block is absent, run
`"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/session-start.sh" --json`.

## Steps

1. `git fetch --prune origin`.
2. Candidates are local branches merged into `origin/<base>`, excluding the current branch and the long-lived ones (default, integration, qa from the context, plus `main`, `master`, `develop`):

   ```bash
   git branch --format='%(refname:short)' --merged "origin/<base>" \
     | grep -vxE "$(git branch --show-current)|<default>|<integration>|<qa>|main|master|develop"
   ```

3. Nothing listed: report that and stop.
4. Show the list and ask with `AskUserQuestion` whether to delete all of them (the user can answer with a subset).
5. On approval: `git branch -d <branch>` for each (plain `-d`; if git refuses because a branch is not fully merged, leave it and report it instead of forcing).
6. Report the count and the names deleted, and any left behind.
