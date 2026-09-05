#!/usr/bin/env bats
# Tests for hooks/scripts/verify-gate.sh (spec: verify-gate).
SCRIPT="$BATS_TEST_DIRNAME/../scripts/verify-gate.sh"
BASE="$BATS_TEST_DIRNAME/../scripts/session-baseline.sh"
setup() {
  export USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  unset USKN_SKIP_VERIFY
  R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R"
  # Makefile verify target: passes unless FAIL file exists; counts runs
  printf 'verify:\n\t@echo run >> runs.log\n\t@if [ -f FAIL ]; then echo "1 test failed: expected 2 got 3"; exit 2; fi\n\t@echo verify-ok\n' > "$R/Makefile"
  ( cd "$R" && git init -q -b main && git add -A && git commit -q -m init )
  printf '{"session_id":"sid","cwd":"%s","hook_event_name":"SessionStart","source":"startup"}' "$R" | "$BASE"
}
stop() { printf '{"session_id":"sid","cwd":"%s","hook_event_name":"Stop","stop_hook_active":%s%s}' "$R" "${1:-false}" "${2:-}" | "$SCRIPT"; }
runs() { [ -f "$R/runs.log" ] && wc -l < "$R/runs.log" || echo 0; }

@test "no change since baseline: silent, verify not run" {
  run stop; [ "$status" -eq 0 ] && [ -z "$output" ]; [ "$(runs)" -eq 0 ]
}

@test "change + passing verify: silent, verified fingerprint recorded, no rerun without further change" {
  echo x > "$R/new.txt"
  run stop; [ "$status" -eq 0 ] && [ -z "$output" ]; [ "$(runs)" -eq 1 ]
  [ -s "$USKN_STATE_DIR/sessions/sid/verified" ]
  run stop; [ -z "$output" ]; [ "$(runs)" -eq 1 ]
  echo y > "$R/new.txt"
  run stop; [ "$(runs)" -eq 2 ]
}

@test "change + failing verify: block with reason naming the command and the failure" {
  touch "$R/FAIL"
  run stop; [ "$status" -eq 0 ]
  echo "$output" | jq -e '.decision == "block" and .hookSpecificOutput.decision == "block"' >/dev/null
  echo "$output" | jq -r '.reason' | grep -q "make verify"
  echo "$output" | jq -r '.reason' | grep -q "expected 2 got 3"
  echo "$output" | jq -r '.reason' | grep -q "USKN_SKIP_VERIFY"
  [ ! -e "$USKN_STATE_DIR/sessions/sid/verified" ]
}

@test "stop_hook_active: silent even when failing" {
  touch "$R/FAIL"; run stop true; [ -z "$output" ]; [ "$(runs)" -eq 0 ]
}

@test "USKN_SKIP_VERIFY=1: silent" {
  touch "$R/FAIL"; USKN_SKIP_VERIFY=1 run stop; [ -z "$output" ]; [ "$(runs)" -eq 0 ]
}

@test "subagent (agent_type present): silent" {
  touch "$R/FAIL"; run stop false ',"agent_type":"Explore","agent_id":"a1"'; [ -z "$output" ]; [ "$(runs)" -eq 0 ]
}

@test "no verify convention: silent" {
  rm "$R/Makefile"; ( cd "$R" && git commit -qam "drop makefile" ); echo x > "$R/new.txt"
  run stop; [ -z "$output" ]
}

@test "outside git: silent" {
  mkdir -p "$BATS_TEST_TMPDIR/plain"
  run bash -c "printf '{\"session_id\":\"s9\",\"cwd\":\"$BATS_TEST_TMPDIR/plain\",\"stop_hook_active\":false}' | '$SCRIPT'"
  [ "$status" -eq 0 ] && [ -z "$output" ]
}

@test "package.json with scripts.verify and pnpm-lock.yaml uses pnpm run verify" {
  rm "$R/Makefile"; echo '{"scripts":{"verify":"true"}}' > "$R/package.json"; touch "$R/pnpm-lock.yaml"
  ( cd "$R" && git add -A && git commit -qm pkg )
  fake="$BATS_TEST_TMPDIR/bin"; mkdir -p "$fake"; printf '#!/usr/bin/env bash\necho "pnpm $*" >> "%s/calls.log"\n' "$BATS_TEST_TMPDIR" > "$fake/pnpm"; chmod +x "$fake/pnpm"
  echo x > "$R/new.txt"
  PATH="$fake:$PATH" run stop; [ -z "$output" ]
  grep -q "pnpm run verify" "$BATS_TEST_TMPDIR/calls.log"
}

@test "missing baseline: records it and does not verify this time" {
  rm -rf "$USKN_STATE_DIR"; touch "$R/FAIL"
  run stop; [ -z "$output" ]; [ "$(runs)" -eq 0 ]; [ -s "$USKN_STATE_DIR/sessions/sid/baseline" ]
}
