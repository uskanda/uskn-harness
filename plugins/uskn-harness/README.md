# uskn-harness (Claude Code plugin)

Loaded as a skills-directory plugin: `uskn-harness sync` symlinks this directory to
`~/.claude/skills/uskn-harness`. It carries hooks and the short commands in `bin/`; skills are symlinked
individually.

- `hooks/hooks.json`: SessionStart (`session-start.sh`, `session-baseline.sh`), PreToolUse (`grilling-guard.sh`,
  `write-guard.sh` on Write/Edit/NotebookEdit; `bash-guard.sh` on Bash), PostToolUse (`textlint-check.sh`,
  `terms-check.sh` on Write/Edit), Stop (`verify-gate.sh`)
- `if` in `hooks.json`: `textlint-check.sh` and `terms-check.sh` start only for `**/*.md`, `grilling-guard.sh` only
  under `**/openspec/changes/**`. An `if` holds one rule and `Edit(<pattern>)` matches the Edit tool only, so each sits
  once under a `Write` matcher and once under an `Edit` matcher. The scripts filter the same way for versions of
  Claude Code without `if`.
- `verify-gate.sh` runs `make verify-fast` when the Makefile has that target, else the verify convention, at the
  git top level of cwd. It blocks at most 3 times in a turn, then lets the turn end with a `systemMessage`.
- `bin/`: short commands for skills, on the Bash tool's PATH while the plugin is enabled. `uskn-repo-context` runs
  `session-start.sh` and `uskn-terms-check` runs `terms-check.sh`, with the same arguments. Hooks do not get this
  PATH and call the scripts directly.
- `hooks/scripts/`: canonical hook bodies (bash + jq). Another tool would call the same scripts through
  `~/.local/share/uskn-harness`; no such adapter exists yet.
- `hooks/tests/`: bats tests, run by `make verify`.

## When the hooks run

Stop hooks run only when a turn ends normally (`end_turn`). An interrupted turn or a usage-limit cut does not run
them. Evidence that a Stop ran: the session's transcript `.jsonl` gains a `stop_hook_summary` line, and
`~/.local/state/uskn-harness/sessions/<session_id>/` gains `verify.log` when the tree changed. `uskn-harness sync`
removes session directories untouched for 30 days.
