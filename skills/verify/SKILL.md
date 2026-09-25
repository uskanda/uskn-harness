---
name: verify
description: Run the repository's checks (make verify, else pnpm or npm run verify, else what CI runs) and fix what fails. Use when the verify gate blocked a stop, before a pull request, or when asked to verify.
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# verify: run the repository's checks and make them pass

The Stop hook `verify-gate` runs the same command automatically when the working tree changed in this session
and blocks finishing while it fails. This skill is the manual form and the recovery path.

## Evidence before claims

Any claim that work is done, fixed, or passing comes after a run of the check in this turn, and the report states
the command and its result (exit code, or the failure count) before the claim. A run from an earlier turn, or a
narrower command (one test file) while a verify convention exists, is not evidence.

## Find the convention (same order as the hook)

1. `Makefile` (or `GNUmakefile`) at the repository root with a `verify:` target → `make verify`
2. `package.json` with `scripts.verify` → `pnpm run verify` if `pnpm-lock.yaml` exists, otherwise `npm run verify`
3. Nothing → this repository has no verify convention. Say so plainly, then take the CI branch below.

## No convention: derive the checks from CI

1. Read the CI configuration: the workflows under `.github/workflows/` and `.gitlab-ci.yml`.
2. List the check commands the jobs run (lint, format check, type check, tests, build). Skip deploy, release, and
   publish steps, and steps that need secrets or services the machine lacks.
3. Run each command in the directory the job runs it in: the step's or the job's working directory, or a `cd`
   in its script.
4. Report each command with pass or fail, say that the checks came from the CI configuration because no verify
   convention exists, and suggest adding a `verify` target that runs them.

With neither a convention nor CI configuration, say both are missing, suggest the `verify` target, and do not
claim to have verified anything.

## Run and fix

1. Run the command from the repository root and read the whole output, not only the exit code.
2. On failure, fix the root cause in the code or tests, then run the same command again. Repeat until it passes.
3. A failure that is not caused by the code (unreachable service, missing credentials, network) is reported as such with the evidence, not "fixed" by weakening the check.
4. Do not commit; that is the `commit` skill's job.

## Report

- The command used, pass or fail with the exit code or failure count, and how long it took.
- What you changed to make it pass, if anything.
- If the gate blocked you: the log is at `~/.local/state/uskn-harness/sessions/<session>/verify.log`.

## Example

A repository with no `verify` target and one workflow under `.github/workflows/`. Its test job runs `npm ci`,
then `npm run lint` and `npm test` with the working directory `web`. You run both there: lint passes, one test
fails. You fix the cause and run `npm test` again, which passes. The report (in the user's language):

> This repository has no verify convention; the checks below come from the CI workflow.
> In `web`: `npm run lint` exit 0. `npm test` failed once (1 of 42), passed after fixing the date boundary in the
> parser: 42 passed, exit 0.
> Suggestion: a `verify` target in the Makefile that runs `npm run lint` and `npm test` in `web`.
