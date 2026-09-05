#!/usr/bin/env bats
# Tests for hooks/scripts/write-guard.sh (spec: write-guard).
SCRIPT="$BATS_TEST_DIRNAME/../scripts/write-guard.sh"
setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; export USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"; export TMPDIR="$BATS_TEST_TMPDIR/tmpdir"
  export GIT_CONFIG_GLOBAL=/dev/null
  ROOT="$BATS_TEST_TMPDIR/repos/a"; OTHER="$BATS_TEST_TMPDIR/repos/b"; mkdir -p "$ROOT/src" "$OTHER" "$TMPDIR" "$HOME/.ai-sessions/x" "$HOME/.claude/projects/p/memory" "$USKN_STATE_DIR/sessions/sid12345678"
  ( cd "$ROOT" && git init -q -b main )
  export CLAUDE_PROJECT_DIR="$ROOT"
  ln -s "$ROOT" "$BATS_TEST_TMPDIR/link-to-a"
}
call() { printf '{"session_id":"sid12345678","cwd":"%s","tool_name":"%s","tool_input":{"file_path":"%s"}}' "$ROOT" "${2:-Write}" "$1" | "$SCRIPT"; }
denied() { echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null; }

@test "inside the project root: silent (absolute and relative)" {
  run call "$ROOT/src/a.ts"; [ "$status" -eq 0 ]; [ -z "$output" ]
  run call "src/b.ts"; [ -z "$output" ]
}

@test "outside the root: denied, reason mentions /allow-repo" {
  run call "$OTHER/x.md"; [ "$status" -eq 0 ]; denied; echo "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -q "/allow-repo"
  run call "$OTHER/x.md" Edit; denied
  run call "$OTHER/n.ipynb" NotebookEdit; denied
}

@test "allowlist: /tmp, TMPDIR, ~/.ai-sessions, memory dir, state dir are silent" {
  run call "/tmp/claude-1000/x/scratchpad/f"; [ -z "$output" ]
  run call "$TMPDIR/f"; [ -z "$output" ]
  run call "$HOME/.ai-sessions/x/j.md"; [ -z "$output" ]
  run call "$HOME/.claude/projects/p/memory/m.md"; [ -z "$output" ]
  run call "$USKN_STATE_DIR/sessions/sid12345678/allow"; [ -z "$output" ]
}

@test "a path through a symlink to the root is inside" {
  run call "$BATS_TEST_TMPDIR/link-to-a/src/c.ts"; [ -z "$output" ]
}

@test "session allow file lifts the restriction for that path only" {
  echo "$OTHER" > "$USKN_STATE_DIR/sessions/sid12345678/allow"
  run call "$OTHER/x.md"; [ -z "$output" ]
  run call "$BATS_TEST_TMPDIR/repos/c/y.md"; denied
}

@test "without CLAUDE_PROJECT_DIR the git root of cwd is used" {
  unset CLAUDE_PROJECT_DIR
  run bash -c "printf '{\"session_id\":\"sid12345678\",\"cwd\":\"$ROOT/src\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$ROOT/other.ts\"}}' | '$SCRIPT'"; [ -z "$output" ]
  run bash -c "printf '{\"session_id\":\"sid12345678\",\"cwd\":\"$ROOT/src\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$OTHER/z.ts\"}}' | '$SCRIPT'"; denied
}

@test "broken input: silent exit 0" {
  run bash -c "echo nope | '$SCRIPT'"; [ "$status" -eq 0 ]; [ -z "$output" ]
}
