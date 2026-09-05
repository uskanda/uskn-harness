#!/usr/bin/env bats
# Tests for hooks/scripts/allow-repo.sh (spec: allow-repo-skill).
SCRIPT="$BATS_TEST_DIRNAME/../scripts/allow-repo.sh"
setup() { export USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"; mkdir -p "$USKN_STATE_DIR/sessions/abcdef12-full" "$BATS_TEST_TMPDIR/target"; }

@test "appends the resolved path to the session's allow file and lists it" {
  run "$SCRIPT" --session abcdef12 "$BATS_TEST_TMPDIR/target"; [ "$status" -eq 0 ]
  [ "$(cat "$USKN_STATE_DIR/sessions/abcdef12-full/allow")" = "$(cd "$BATS_TEST_TMPDIR/target" && pwd -P)" ]
  run "$SCRIPT" --session abcdef12 --list; [[ "$output" == *"target"* ]]
}

@test "unknown session or missing path fails with a message" {
  run "$SCRIPT" --session zzzz "$BATS_TEST_TMPDIR/target"; [ "$status" -ne 0 ]
  run "$SCRIPT" --session abcdef12 "$BATS_TEST_TMPDIR/nope"; [ "$status" -ne 0 ]
}
