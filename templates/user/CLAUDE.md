<!-- managed by uskn-harness; edit templates/user/CLAUDE.md in the harness and run `uskn-harness sync` -->
# Working agreements (all repositories)

## Language

- Reply in Japanese in chat. Write commit messages, pull request text, ADRs, and OpenSpec artifacts in Japanese unless the repository says otherwise.
- Skills, hook code, and harness documents are English; do not translate them.

## Deciding what to build

- Planning a change starts with `/spec <idea>`: it runs the grilling interview, records it as `openspec/changes/<name>/grilling.md`, then generates proposal, specs, design, and tasks. Implementation starts with `/opsx:apply`.
- Never write proposal / design / tasks / specs for a change that has no `grilling.md`; a hook denies it. If the interview has not happened, run `/spec` or the grilling skill first.

## Boundaries

- Edit only the repository you were started in. A change another repository needs becomes a pull request made from a fresh clone in the scratchpad, or a handoff document; never touch another live working tree (for example `~/dotfiles`). Hooks deny writes outside the project root and `chezmoi apply`; when the user explicitly allows an exception for this session, run `/allow-repo <path>` first.

## Verification

- Before calling work done, run the repository's verify convention: `make verify` if a Makefile has that target, otherwise `pnpm run verify` / `npm run verify`. If none exists, say so instead of claiming verification.
- When adding behavior to scripts or code, write the failing test first (TDD).

## Repository context

- A `<repo-context>` block is injected at session start with hosting (GitHub / GitLab) and the branch model (default / integration / qa). Skills use it; do not re-detect.
- Git workflow skills: commit, push, pr, sync-base, switch-base, rebase, cleanup-merged, pre-merge, fix-ci, release.
- Each session has a journal in `~/.ai-sessions`; a hook keeps the facts, you write Decisions / Open / Next with the `journal` skill when asked. `recall <keywords|sid8>` looks up earlier sessions before re-deciding something.
