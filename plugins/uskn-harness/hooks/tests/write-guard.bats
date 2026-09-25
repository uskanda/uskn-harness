#!/usr/bin/env bats
# Tests for hooks/scripts/write-guard.sh (spec: write-guard).
SCRIPT="$BATS_TEST_DIRNAME/../scripts/write-guard.sh"
setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; export USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"; export TMPDIR="$BATS_TEST_TMPDIR/tmpdir"
  export GIT_CONFIG_GLOBAL=/dev/null
  # The default allowlist (/tmp, $TMPDIR) would cover BATS_TEST_TMPDIR itself, wherever TMPDIR points; use a dedicated one.
  SCRATCH="$BATS_TEST_TMPDIR/scratch"; export USKN_GUARD_ALLOW_DIRS="$SCRATCH"
  ROOT="$BATS_TEST_TMPDIR/repos/a"; OTHER="$BATS_TEST_TMPDIR/repos/b"; mkdir -p "$ROOT/src" "$OTHER" "$SCRATCH" "$TMPDIR" "$HOME/.ai-sessions/x" "$HOME/.claude/projects/p/memory" "$USKN_STATE_DIR/sessions/sid12345678"
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

@test "allowlist: scratch dirs, memory dir, state dir are silent" {
  run call "$SCRATCH/x/scratchpad/f"; [ -z "$output" ]
  run call "$HOME/.claude/projects/p/memory/m.md"; [ -z "$output" ]
  run call "$USKN_STATE_DIR/sessions/sid12345678/notes"; [ -z "$output" ]
}

@test "~/.ai-sessions, where journals used to go, is outside the allowlist: denied like any other path" {
  run call "$HOME/.ai-sessions/x/j.md"
  [ "$status" -eq 0 ]
  denied
}

@test "the session allow file is denied: directly, through a symlink, and even with the state dir allowed" {
  run call "$USKN_STATE_DIR/sessions/sid12345678/allow"
  [ "$status" -eq 0 ]
  denied
  echo "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -q "/allow-repo"
  run call "$USKN_STATE_DIR/sessions/another-session/allow" Edit; denied
  ln -s "$USKN_STATE_DIR" "$SCRATCH/state-link"
  run call "$SCRATCH/state-link/sessions/sid12345678/allow" Edit; denied
  echo "$USKN_STATE_DIR" > "$USKN_STATE_DIR/sessions/sid12345678/allow"
  run call "$USKN_STATE_DIR/sessions/sid12345678/allow"; denied
}

@test "the verify gate's state files are denied, even with the state dir allowed; the log is not" {
  S="$USKN_STATE_DIR/sessions/sid12345678"
  for f in baseline verified verify-blocks; do
    run call "$S/$f"; [ "$status" -eq 0 ]; denied
    run call "$S/$f" Edit; denied
  done
  echo "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -q "USKN_SKIP_VERIFY"
  run call "$USKN_STATE_DIR/sessions/another-session/verified"; denied
  echo "$USKN_STATE_DIR" > "$S/allow"
  run call "$S/baseline" Edit; denied
  run call "$S/verify.log"; [ -z "$output" ]
  run call "$S/baseline-head"; [ -z "$output" ]
}

@test "default allowlist without USKN_GUARD_ALLOW_DIRS: /tmp and TMPDIR are silent" {
  unset USKN_GUARD_ALLOW_DIRS
  run call "/tmp/claude-1000/x/scratchpad/f"; [ -z "$output" ]
  run call "$TMPDIR/f"; [ -z "$output" ]
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

@test "two roots: a worktree of the session repository outside CLAUDE_PROJECT_DIR is inside when it is cwd" {
  git -C "$ROOT" -c user.name=t -c user.email=t@x commit -q --allow-empty -m init
  WT="$BATS_TEST_TMPDIR/repos/a-wt"; git -C "$ROOT" worktree add -q -b wt "$WT"; mkdir -p "$WT/src"
  wt() { printf '{"session_id":"sid12345678","cwd":"%s","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$WT/src" "$1" | "$SCRIPT"; }
  run wt "$WT/x.md"; [ "$status" -eq 0 ]; [ -z "$output" ]
  run wt "$ROOT/y.md"; [ -z "$output" ]
  run wt "$OTHER/z.md"; denied
  echo "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -qF "$(realpath "$WT")"
}

@test "cwd moved into another repository: writing there is denied although it is the cwd's git root" {
  git -C "$OTHER" init -q -b main; mkdir -p "$OTHER/src"
  at() { printf '{"session_id":"sid12345678","cwd":"%s","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1" "$2" | "$SCRIPT"; }
  run at "$OTHER/src" "$OTHER/x.md"; [ "$status" -eq 0 ]; denied
  run at "$OTHER/src" "x.md"; denied
  echo "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -q "/allow-repo"
  run at "$OTHER" "$ROOT/y.md"; [ -z "$output" ]
}

@test "cwd in a subdirectory of the session root: the root is inside, another repository is not" {
  at() { printf '{"session_id":"sid12345678","cwd":"%s","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$ROOT/src" "$1" | "$SCRIPT"; }
  run at "$ROOT/z.md"; [ -z "$output" ]
  run at "../w.md"; [ -z "$output" ]
  run at "$OTHER/z.md"; denied
}

@test "broken input: silent exit 0" {
  run bash -c "echo nope | '$SCRIPT'"; [ "$status" -eq 0 ]; [ -z "$output" ]
}
