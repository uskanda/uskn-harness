# uskn-harness (Claude Code plugin)

Loaded as a skills-directory plugin: `uskn-harness sync` symlinks this directory to
`~/.claude/skills/uskn-harness`. It carries hooks only; skills are symlinked individually.

- `hooks/hooks.json`: SessionStart (`session-start.sh`, `session-baseline.sh`, `journal-recent.sh`), PreToolUse
  (`grilling-guard.sh`, `write-guard.sh` on Write/Edit; `bash-guard.sh` on Bash), PostToolUse (`textlint-check.sh`
  on Write/Edit), Stop (`verify-gate.sh`, `journal-update.sh`), SessionEnd (`journal-end.sh`)
- `hooks/scripts/`: canonical hook bodies (bash + jq). Other tools' adapters under `/hooks/adapters/` call the same
  scripts through `~/.local/share/uskn-harness`.
- `hooks/tests/`: bats tests, run by `make verify`.

## When the hooks run

Stop hooks run only when a turn ends normally (`end_turn`). An interrupted turn or a usage-limit cut does not run
them. SessionEnd runs when the client closes the session; the desktop app may keep a session open for hours.
Evidence that a Stop ran: `~/.local/state/uskn-harness/sessions/<session_id>/` gains `transcript` (and `verify.log`
when the tree changed), and the session's transcript `.jsonl` gains a `stop_hook_summary` line. Before the first
Stop, `journal-update.sh --session <sid8> --ensure` creates the journal on demand.
