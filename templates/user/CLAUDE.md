<!-- managed by uskn-harness; edit templates/user/CLAUDE.md in the harness and run `uskn-harness sync` -->
# Working agreements (all repositories)

## Language

- Reply in Japanese in chat. Write commit messages, pull request text, ADRs, and OpenSpec artifacts in Japanese unless the repository says otherwise.
- Skills, hook code, and harness documents are English; do not translate them.

## Deciding what to build

- A spec decision starts with the grilling interview (`/grill-me`, or the grilling skill). Only after the interview reaches shared understanding do you create OpenSpec artifacts (`/opsx:propose`) and implement (`/opsx:apply`).
- Save the interview outcome as `openspec/changes/<name>/grilling.md` before proposing.

## Boundaries

- Edit only the repository you were started in. A change another repository needs becomes a pull request made from a fresh clone in the scratchpad, or a handoff document; never touch another live working tree (for example `~/dotfiles`).
- Do not run `chezmoi apply` or push to other repositories unless the user asks for it in this session.

## Verification

- Before calling work done, run the repository's verify convention: `make verify` if a Makefile has that target, otherwise `pnpm run verify` / `npm run verify`. If none exists, say so instead of claiming verification.
- When adding behavior to scripts or code, write the failing test first (TDD).

## Repository context

- A `<repo-context>` block is injected at session start with hosting (GitHub / GitLab) and the branch model (default / integration / qa). Skills use it; do not re-detect.
- Git workflow skills: commit, push, pr, sync-base, switch-base, rebase, cleanup-merged, pre-merge, fix-ci, release.
