#!/usr/bin/env bats
# Tests for hooks/scripts/directory-added.sh (spec: directory-added-hook). The DirectoryAdded hook records the
# directory the user added with /add-dir in the session's allow file, through allow-repo.sh.
SCRIPT="$BATS_TEST_DIRNAME/../scripts/directory-added.sh"
SID="abcdef12-3456-7890-abcd-ef1234567890"
setup() {
  export USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"
  mkdir -p "$USKN_STATE_DIR/sessions/$SID" "$BATS_TEST_TMPDIR/target"
  ALLOW="$USKN_STATE_DIR/sessions/$SID/allow"
  REAL="$(cd "$BATS_TEST_TMPDIR/target" && pwd -P)"
}
added() { # <directory> [source] [session id]
  jq -c -n --arg d "$1" --arg s "${2:-slash_command}" --arg sid "${3:-$SID}" \
    '{session_id:$sid, cwd:"/x", hook_event_name:"DirectoryAdded", directory:$d, source:$s}' | "$SCRIPT"
}

@test "/add-dir: the resolved directory goes into the session's allow file and a systemMessage names it" {
  run added "$BATS_TEST_TMPDIR/target"
  [ "$status" -eq 0 ]
  [ "$(cat "$ALLOW")" = "$REAL" ]
  echo "$output" | jq -e --arg p "$REAL" '.systemMessage | contains($p)' >/dev/null
}

@test "register_repo_root is recorded the same way" {
  run added "$BATS_TEST_TMPDIR/target" register_repo_root
  [ "$status" -eq 0 ]
  [ "$(cat "$ALLOW")" = "$REAL" ]
}

@test "adding the same directory twice keeps one line" {
  added "$BATS_TEST_TMPDIR/target" >/dev/null
  added "$BATS_TEST_TMPDIR/target" >/dev/null
  [ "$(wc -l < "$ALLOW" | tr -d ' ')" = 1 ]
}

@test "input that is not JSON: silent exit 0" {
  run bash -c "echo nope | '$SCRIPT'"
  [ "$status" -eq 0 ]; [ -z "$output" ]
}

@test "a directory that does not exist, or a session without state: silent exit 0, nothing recorded" {
  run added "$BATS_TEST_TMPDIR/nope"
  [ "$status" -eq 0 ]; [ -z "$output" ]; [ ! -e "$ALLOW" ]
  run added "$BATS_TEST_TMPDIR/target" slash_command "zzzzzzzz-none"
  [ "$status" -eq 0 ]; [ -z "$output" ]; [ ! -e "$ALLOW" ]
}
