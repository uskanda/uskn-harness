# uskn-harness (Claude Code plugin)

Loaded as a skills-directory plugin: `uskn-harness sync` symlinks this directory to
`~/.claude/skills/uskn-harness`. It carries hooks only; skills are symlinked individually.

- `hooks/hooks.json`: SessionStart (`session-start.sh`, `session-baseline.sh`), PreToolUse (`grilling-guard.sh`,
  `write-guard.sh` on Write/Edit/NotebookEdit; `bash-guard.sh` on Bash), PostToolUse (`textlint-check.sh`,
  `terms-check.sh` on Write/Edit), Stop (`verify-gate.sh`)
- `hooks/scripts/`: canonical hook bodies (bash + jq). Another tool would call the same scripts through
  `~/.local/share/uskn-harness`; no such adapter exists yet.
- `hooks/tests/`: bats tests, run by `make verify`.

## When the hooks run

Stop hooks run only when a turn ends normally (`end_turn`). An interrupted turn or a usage-limit cut does not run
them. Evidence that a Stop ran: the session's transcript `.jsonl` gains a `stop_hook_summary` line, and
`~/.local/state/uskn-harness/sessions/<session_id>/` gains `verify.log` when the tree changed. `uskn-harness sync`
removes session directories untouched for 30 days.
