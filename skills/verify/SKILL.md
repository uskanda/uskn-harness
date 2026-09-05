---
name: verify
description: Find and run the repository's verify convention (make verify, else pnpm run verify / npm run verify), fix what fails, and report honestly when no convention exists. Use before calling work done, when the verify gate hook blocked a stop, or when the user asks to verify or check the build.
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# verify: run the repository's checks and make them pass

The Stop hook `verify-gate` runs the same command automatically when the working tree changed in this session
and blocks finishing while it fails. This skill is the manual form and the recovery path.

## Find the convention (same order as the hook)

1. `Makefile` (or `GNUmakefile`) at the repository root with a `verify:` target → `make verify`
2. `package.json` with `scripts.verify` → `pnpm run verify` if `pnpm-lock.yaml` exists, otherwise `npm run verify`
3. Nothing → say plainly that this repository has no verify convention. Do not claim to have verified anything.
   Suggest adding a `verify` target that runs the repository's lint, type check, and tests (see `pre-merge` for how to discover them).

## Run and fix

1. Run the command from the repository root and read the whole output, not only the exit code.
2. On failure, fix the root cause in the code or tests, then run the same command again. Repeat until it passes.
3. A failure that is not caused by the code (unreachable service, missing credentials, network) is reported as such with the evidence, not "fixed" by weakening the check.
4. Do not commit; that is the `commit` skill's job.

## Report

- The command used, pass or fail, and how long it took.
- What you changed to make it pass, if anything.
- If the gate blocked you: the log is at `~/.local/state/uskn-harness/sessions/<session>/verify.log`.
