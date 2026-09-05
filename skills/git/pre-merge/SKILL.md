---
name: pre-merge
description: Run locally every check that CI would run (lint, format, types, tests) and fix what fails, without committing. Use before opening a pull request or when the user asks to make CI green ahead of time.
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# Run the CI checks locally and fix failures

## Find the checks

1. The repository's verify convention comes first: `make verify` if a Makefile has that target, else `pnpm run verify` / `npm run verify` if package.json defines it. When it exists it is the authoritative set of checks.
2. Otherwise derive the checks from `.github/workflows/`, `.gitlab-ci.yml`, `Makefile`, and the scripts in `package.json` / `pyproject.toml`. Mind the layout (monorepo, separate frontend and backend) and run each check where CI runs it.

Typical checks when nothing is declared:

- Python: `ruff check .` / `flake8`; `ruff format --check .` / `black --check`; `mypy`; `pytest`
- TypeScript / JavaScript: `eslint`; `prettier --check`; `tsc --noEmit`; `vitest run` / `jest`
- Prefer `make lint`, `make test`, and similar targets when they exist

## Rules

- Report each check as pass or fail, briefly.
- When you fix something, say what you changed and rerun that check until it passes.
- Do not commit when everything passes; committing is the `commit` skill's job.
- A failure that is not caused by the code (database unreachable, missing service, flaky network) is skipped and reported as such, not "fixed".
