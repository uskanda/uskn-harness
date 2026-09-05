---
name: rebase
description: Reorganize the commits on the current branch since it diverged from its base into 1–5 meaningful commits, without interactive git. Use when the user asks to clean up, squash, or tidy commits before a pull request. Optional argument: the base branch (defaults to the integration branch).
allowed-tools: Bash, AskUserQuestion, Skill
---

# Reorganize the commits on this branch

Goal: the commits since the branch diverged from its base become 1–5 well-formed commits, with the tree unchanged.

## Context

Use the `<repo-context>` block injected at session start for the integration branch. If it is absent, run
`"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/session-start.sh" --json`.
The base is `$ARGUMENTS` when given, otherwise the integration branch.

## Steps

1. **Inspect.** `git status --porcelain` must be empty; otherwise stop and ask the user to commit or stash first. Record the branch (`git branch --show-current`) and the base point: `BASE=$(git merge-base HEAD origin/<base>)` (fall back to the local base branch if the remote-tracking ref is missing). List the commits: `git log --oneline "$BASE"..HEAD`.
2. **Back up.** `git branch backup/<branch>-$(date +%Y%m%d%H%M%S)` so nothing can be lost.
3. **Plan the groups.** Read the diff per commit and decide 1–5 groups by concern. Show the plan briefly.
4. **Rebuild without interactive git.** Interactive rebase needs an editor, so use a soft reset instead: `git reset --soft "$BASE"`. Everything is now staged. Unstage all (`git reset -q`) and commit group by group with the `commit` skill's message rules (`git add <paths>` per group, message via `git commit -F -`). `git add -p` is interactive and not available here; when one file belongs to two groups, split by file or accept the coarser grouping.
5. **Verify.** `git diff backup/<branch>-... --stat` must be empty (same tree). `git log --oneline "$BASE"..HEAD` shows the new commits.
6. **Publishing.** If the branch was already pushed, the remote now needs a force push. Do not run it. Tell the user the exact command (`git push --force-with-lease origin <branch>`) and let them decide.
7. Report the before/after commit lists and the backup branch name. Delete the backup only when the user says so.

## Message format

Line 1: what was done. Line 2: blank. Lines 3+: 2–5 lines of detail. Language: follow the user or repository instructions; default to Japanese.
