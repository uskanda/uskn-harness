---
name: fix-ci
description: Investigate a failing CI run on GitHub Actions or GitLab CI, fix the cause in the working tree, and report. Argument: a PR/MR number, a URL of a PR/MR, pipeline, or job, or nothing for the current branch.
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# Investigate and fix a failing CI run

## Argument

- **number**: the pull request (GitHub) or merge request (GitLab) number
- **URL**: a PR/MR, pipeline, run, or job URL; use it directly to locate the target
- **nothing**: the latest PR/MR or pipeline for the current branch

## Context

Use the platform from the `<repo-context>` block injected at session start. If the block is absent, run
`"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/session-start.sh" --plain hosting`.
If the argument is a URL on a different host than the repository, the URL's host wins.

## GitLab

1. Locate the MR: number → `glab mr view <n>`; URL → extract the MR number or pipeline / job id; nothing → `glab mr view`.
2. Find the failed pipeline and job: `glab ci status` / `glab ci view`; MR pipelines through `glab mr view <n>` or `glab api`.
3. Get the log: `glab ci trace <job-id>` (or `glab api projects/:id/jobs/<job-id>/trace` when that fails).
4. Read the log for the root cause.

## GitHub

1. Locate the PR: number → `gh pr view <n>`; URL → extract the PR number or run id; nothing → `gh pr view`.
2. Failed checks: `gh pr checks <n>`; runs: `gh run list` / `gh run view <run-id>`.
3. Log of the failed steps: `gh run view <run-id> --log-failed`.
4. Read the log for the root cause.

## Fixing

1. Identify the root cause (lint, format, types, tests, build, dependencies, CI configuration).
2. Code problems: fix them and, where possible, rerun the same check locally (the `pre-merge` skill describes how).
3. CI configuration problems: fix the workflow or pipeline file.
4. Not code-related (infrastructure, network, external service, flaky test): do not guess a fix; report it and suggest a rerun.

## Rules

- No commit and no push unless the user asked for it explicitly. Committing is the `commit` skill's job.
- Quote only the relevant part of long logs (error lines, stack traces).
- Several failing jobs: report each cause and action.

## Report

1. Target (PR/MR number, URL, branch)
2. Failing jobs and their causes
3. Changes made (files and what changed)
4. Local re-check result, when it could be run
5. What remains (push, rerun, user decisions)
