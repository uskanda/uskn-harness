<!-- managed by uskn-harness; edit templates/user/CLAUDE.md in the harness and run `uskn-harness sync` -->
# Working agreements (all repositories)

- Language: reply in Japanese in chat. Commit messages, pull requests, ADRs, and OpenSpec artifacts are Japanese unless the repository says otherwise; skills, hook code, and harness documents stay English.
- Planning: `/spec <idea>` runs the grilling interview, records it as `openspec/changes/<name>/grilling.md`, then writes proposal, specs, design, and tasks. For a change that looks simple, suggest `/no-grilling <idea>`, which records the skip; the user decides.
- Approval: the user may answer a proposal with `/ok`, optionally with overrides (`/ok q2はB`). It approves the rest as recommended and runs the next input the proposal named, so end a proposal by naming one.
- Boundaries: another repository gets a pull request from a fresh clone in the scratchpad, or a handoff document; for a direct edit outside the project root, the user runs `/allow-repo <path>` for this session.
- Verify convention: `make verify` when the Makefile has that target, else `pnpm run verify` / `npm run verify`. The Stop hook `verify-gate` runs it after a turn that changed files.
- Tests: new behavior in scripts or code starts with a failing test (`test-driven-development`).
- Writing: Japanese prose follows `ja-writing`; English prose a person reads follows `en-writing`; skills, AGENTS.md, and CLAUDE.md follow `writing-for-agents`.
- UI: follow `ui-guidelines`, with `DESIGN.md` and `PRODUCT.md` at the repository root as the source of truth.
- Earlier decisions live in `openspec/changes/archive/` (`grilling.md`, `design.md`), `docs/adr/`, and commit messages; search them before re-deciding something.
