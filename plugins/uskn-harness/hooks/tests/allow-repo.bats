#!/usr/bin/env bats
# Tests for hooks/scripts/allow-repo.sh (spec: allow-repo-skill).
SCRIPT="$BATS_TEST_DIRNAME/../scripts/allow-repo.sh"
setup() { export USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"; mkdir -p "$USKN_STATE_DIR/sessions/abcdef12-full" "$BATS_TEST_TMPDIR/target"; }

@test "appends the resolved path to the session's allow file and lists it" {
  run "$SCRIPT" --session abcdef12 "$BATS_TEST_TMPDIR/target"; [ "$status" -eq 0 ]
  [ "$(cat "$USKN_STATE_DIR/sessions/abcdef12-full/allow")" = "$(cd "$BATS_TEST_TMPDIR/target" && pwd -P)" ]
  run "$SCRIPT" --session abcdef12 --list; [[ "$output" == *"target"* ]]
}

@test "without --session, or with an empty one, the first 8 characters of CLAUDE_CODE_SESSION_ID are used" {
  CLAUDE_CODE_SESSION_ID=abcdef12-3456-7890 run "$SCRIPT" "$BATS_TEST_TMPDIR/target"
  [ "$status" -eq 0 ]
  [[ "$output" == *"abcdef12"* ]]
  [ "$(cat "$USKN_STATE_DIR/sessions/abcdef12-full/allow")" = "$(cd "$BATS_TEST_TMPDIR/target" && pwd -P)" ]
  CLAUDE_CODE_SESSION_ID=abcdef12-3456-7890 run "$SCRIPT" --session "" --list
  [ "$status" -eq 0 ]
  [[ "$output" == *"target"* ]]
}

@test "no session id at all: exit 2 with a message that names the session id, not <repo-context>" {
  run env -u CLAUDE_CODE_SESSION_ID "$SCRIPT" "$BATS_TEST_TMPDIR/target"
  [ "$status" -eq 2 ]
  [[ "$output" == *"session id"* ]]
  [[ "$output" != *"repo-context"* ]]
  [ ! -e "$USKN_STATE_DIR/sessions/abcdef12-full/allow" ]
}

@test "unknown session or missing path fails with a message" {
  run "$SCRIPT" --session zzzz "$BATS_TEST_TMPDIR/target"; [ "$status" -ne 0 ]
  run "$SCRIPT" --session abcdef12 "$BATS_TEST_TMPDIR/nope"; [ "$status" -ne 0 ]
}
