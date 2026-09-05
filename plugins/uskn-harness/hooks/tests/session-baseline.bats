#!/usr/bin/env bats
# Tests for hooks/scripts/session-baseline.sh (spec: session-baseline).
SCRIPT="$BATS_TEST_DIRNAME/../scripts/session-baseline.sh"
setup() {
  export USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R"; ( cd "$R" && git init -q -b main && git commit -q --allow-empty -m init )
}
fire() { printf '{"session_id":"%s","cwd":"%s","hook_event_name":"SessionStart","source":"%s"}' "$1" "$2" "${3:-startup}" | "$SCRIPT"; }

@test "records baseline, project, started for a git repo; prints nothing" {
  run fire sid1 "$R"
  [ "$status" -eq 0 ] && [ -z "$output" ]
  [ -s "$USKN_STATE_DIR/sessions/sid1/baseline" ]
  [ "$(cat "$USKN_STATE_DIR/sessions/sid1/project")" = "$(cd "$R" && pwd -P)" ]
  grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$USKN_STATE_DIR/sessions/sid1/started"
}

@test "outside git: nothing is created" {
  mkdir -p "$BATS_TEST_TMPDIR/plain"
  run fire sid2 "$BATS_TEST_TMPDIR/plain"
  [ "$status" -eq 0 ] && [ -z "$output" ]
  [ ! -e "$USKN_STATE_DIR/sessions/sid2" ]
}

@test "a second SessionStart for the same session keeps the first baseline" {
  fire sid3 "$R"; first="$(cat "$USKN_STATE_DIR/sessions/sid3/baseline")"
  echo change > "$R/f.txt"
  fire sid3 "$R" compact
  [ "$(cat "$USKN_STATE_DIR/sessions/sid3/baseline")" = "$first" ]
}
