---
name: push
description: Push the current branch to origin. If there are uncommitted changes, commits them first via the commit skill; if the target branch is protected, asks before creating a new branch. Optional argument: the new branch name to use when one is needed.
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion, Skill
---

# Push the current branch to origin

Behavior depends on whether there are uncommitted changes and whether the current branch is protected:

- protected + uncommitted changes: confirm with the user, create a new branch, commit with `commit`, push the new branch
- not protected + uncommitted changes: commit with `commit`, push the current branch
- no uncommitted changes: push as is

## Context

Use the `<repo-context>` block injected at session start (platform, CLI, default / integration / qa branches). If it is absent, run
`"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/session-start.sh" --json`
and use its values. Do not re-detect by hand when either is available.

## Steps

### 1. Preconditions

- `git rev-parse --show-toplevel` succeeds (inside a repository) and `git remote get-url origin` succeeds. If either fails, stop and report.
- `git branch --show-current` gives the current branch. Stop on a detached HEAD.

### 2. Uncommitted changes?

`git status --porcelain` (includes untracked files). Nothing listed: go to step 5. Otherwise: step 3.

### 3. Is the target branch protected?

Decide in this order and remember which source decided, because the report must name it.

**Priority 1: an explicit statement in the repository instructions.** If `AGENTS.md` or `CLAUDE.md` (or the equivalent project instruction file) states whether the branch is protected, follow it and skip the API and the heuristic. Examples: "`master` has no branch protection; push directly" is not-protected; "`main` is protected; never push to it directly" is protected. No confirmation is needed when the statement exists.

**Priority 2: the host API.**

GitHub (`gh` authenticated):

```bash
gh api "repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/branches/<BRANCH>" --jq .protected
```

`true` means protected. The field reflects both classic branch protection and rulesets.

GitLab (`glab` authenticated). Protection rules can be wildcards such as `release/*`, so list them and glob-match instead of looking the branch up by name:

```bash
PROJ=$(git remote get-url origin | sed -E 's#^(https?://[^/]+/|git@[^:]+:|ssh://git@[^/]+/)##; s#\.git$##' | sed 's#/#%2F#g')
BRANCH=<BRANCH>; PROTECTED=no
while IFS= read -r pat; do case "$BRANCH" in $pat) PROTECTED=yes;; esac; done \
  < <(glab api "projects/$PROJ/protected_branches" --paginate | jq -r '.[].name')
echo "$PROTECTED"
```

**Priority 3: fallback by name.** When there is no statement and the API is unavailable (CLI missing or unauthenticated, offline, unknown host), treat these as protected: the default, integration, and qa branches from the context, plus `main`, `master`, `develop`, `staging`, `production`, and `release/*`. Everything else is not protected. Say in the report that the decision came from the name heuristic.

### 4-A. Protected, with uncommitted changes

1. Choose a new branch name. If `$ARGUMENTS` names one, use it without asking. Otherwise propose an ASCII kebab-case name that summarizes the change, such as `feature/add-push-skill`.
2. Ask the user with `AskUserQuestion`: say the current branch is protected and how that was decided, and offer the proposed name (the user can type another). If the user declines, stop without doing anything.
3. `git switch -c <NEW_BRANCH>`. Uncommitted changes carry over to the new branch.
4. Run the `commit` skill with the Skill tool.
5. `git push -u origin <NEW_BRANCH>`.

### 4-B. Not protected, with uncommitted changes

1. Run the `commit` skill with the Skill tool (no confirmation needed).
2. Go to step 5.

### 5. Push

- Upstream already set (`git rev-parse --abbrev-ref --symbolic-full-name @{u}` succeeds): `git push`
- Otherwise: `git push -u origin HEAD`
- If the push is rejected (protected branch, non-fast-forward, and so on), do not retry with any `--force` variant. Report the rejection verbatim and stop.

### 6. Report

`git status -sb` to confirm the branch is in sync, then report: the branch pushed (and whether it was newly created), the protection decision and its source (instructions / API / name heuristic), and the commits created (`git log --oneline -3`).

## Notes

- `--force` and `--force-with-lease` are never used by this skill. The user has to ask for them explicitly.
- Protected branch with no uncommitted changes: push as is and let the remote decide.
