---
name: audit
description: Audit an implemented OpenSpec change against its specs, in a fork without the conversation that built it. Use before archiving a change or opening its pull request.
argument-hint: "[change-name ...]"
context: fork
model: opus
effort: high
background: false
allowed-tools: Bash, Read, Grep, Glob
---

# audit: judge a change against its specs

This skill runs as a fork: it sees the repository and its arguments, not the conversation that implemented the
change. That separation is the point. An implementer praises its own work, so every claim counts only once you have
checked it yourself. Read `references/auditor.md` before you judge; it holds the severity rules.

## Targets

`$ARGUMENTS` is zero or more change names under `openspec/changes/`.

- Names given: audit each of them.
- No names: run `uskn-repo-context --plain branches` and take the `integration=` value. Then run
  `uskn-archive-check --base origin/<integration>`; it prints the unarchived changes this branch touched, one per line.
  Audit each of them. When it prints nothing, report that there is nothing to audit and stop.

## Before you start

Run `git status --porcelain`. When it prints anything, do not audit: report the uncommitted paths and ask for a commit
first (the `commit` skill). The audit compares committed work, and the restore step below must not touch the
user's edits. Record `git rev-parse HEAD`.

## Checks, per change

1. Computational checks. Run each and record the result.
   - The verify convention at the repository root: `make verify`, else `pnpm run verify` / `npm run verify`. The full
     convention, never `verify-fast`.
   - `openspec validate <name> --strict`
   - The unchecked lines of `openspec/changes/<name>/tasks.md` (`- [ ]`)
   - `uskn-diff-check --base origin/<integration> --allow-from openspec/changes/<name>/tasks.md`
2. Scenarios. Read every `#### Scenario:` under `openspec/changes/<name>/specs/`. For each, find the test that checks
   it and run that test. A scenario that no test checks is a `fail`.
3. The diff. Read `git diff origin/<integration>...HEAD` for clear bugs. Each `verify-setting` line from the diff check
   needs a reason in the change's `tasks.md` or `design.md`.
4. Restore. Run `git status --porcelain` and compare HEAD with the recorded one. When a tracked file changed, list it
   as an advisory finding and run `git restore --staged --worktree -- <path>`. List new untracked files without
   deleting them; 0-byte files that appear only while a command runs are the sandbox's, so leave them out.

## Verdict

Report one verdict per change in the shape of `references/verdict.schema.json`, as a fenced JSON block, followed by
two or three sentences for the reader:

- `verdict`: `pass` when every computational check passed, every scenario passed, and no finding is blocking; else
  `fail`.
- `scenarios`: every scenario with the tests you ran and `pass` or `fail`.
- `findings`: severity, file, line, a one-line summary, and the evidence (the command and its output, or the lines).
- `question`: one question when the specs are ambiguous and the code cannot settle it; otherwise `""`.

You do not fix anything. Name the fix in the finding and let the caller decide.

## Example

`/audit add-csv-export` on a branch where `make verify` passes and tasks.md is all checked. The specs have three
scenarios; you find and run tests for two, and none checks "空のファイル". `uskn-diff-check` prints
`skip-added tests/export.test.ts: it.skip("quotes", ...)`, and tasks.md does not mention that file. The verdict is
`fail` with two blocking findings: the scenario without a test, and the skipped test. A variable name you would
have chosen differently is an advisory finding and does not change the verdict.
