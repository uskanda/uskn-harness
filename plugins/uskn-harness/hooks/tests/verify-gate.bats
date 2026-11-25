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
# refute <command...>: fails when the command succeeds (a bare `! cmd` mid-test never fails a bats test).
refute() { ! "$@"; }
# path_without <cmd>...: a directory of links to everything on PATH except the named commands (first match wins)
path_without() {
  local farm="$BATS_TEST_TMPDIR/farm" d x
  mkdir -p "$farm"
  local IFS=:
  for d in $PATH; do [ -d "$d" ] && ln -s "$d"/* "$farm"/ 2>/dev/null; done
  for x in "$@"; do rm -f "$farm/$x"; done
  printf '%s' "$farm"
}

@test "no change since baseline: silent, verify not run" {
  run stop; [ "$status" -eq 0 ]; [ -z "$output" ]; [ "$(runs)" -eq 0 ]
}

@test "change + passing verify: silent, verified fingerprint recorded, no rerun without further change" {
  echo x > "$R/new.txt"
  run stop; [ "$status" -eq 0 ]; [ -z "$output" ]; [ "$(runs)" -eq 1 ]
  [ -s "$USKN_STATE_DIR/sessions/sid/verified" ]
  run stop; [ -z "$output" ]; [ "$(runs)" -eq 1 ]
  echo y > "$R/new.txt"
  run stop; [ "$(runs)" -eq 2 ]
}

@test "change + failing verify: block with reason naming the command and the failure" {
  touch "$R/FAIL"
  run stop; [ "$status" -eq 0 ]
  echo "$output" | jq -e '.decision == "block"' >/dev/null
  echo "$output" | jq -e 'keys == ["decision", "reason"]' >/dev/null   # the Stop schema has no hookSpecificOutput decision
  echo "$output" | jq -r '.reason' | grep -q "make verify"
  echo "$output" | jq -r '.reason' | grep -q "expected 2 got 3"
  echo "$output" | jq -r '.reason' | grep -q "USKN_SKIP_VERIFY"
  [ ! -e "$USKN_STATE_DIR/sessions/sid/verified" ]
}

@test "without timeout and gtimeout, a verify that runs past the cap is stopped and blocks as timed out" {
  printf 'verify:\n\t@sleep 30\n' > "$R/Makefile"
  P="$(path_without timeout gtimeout)"
  start="$(date +%s)"
  HOME="$BATS_TEST_TMPDIR/h" USKN_VERIFY_TIMEOUT=1 PATH="$P" run stop
  [ "$status" -eq 0 ]
  [ $(( $(date +%s) - start )) -lt 15 ]
  echo "$output" | jq -e '.decision == "block"' >/dev/null
  echo "$output" | jq -r '.reason' | grep -q "timed out after 1s"
}

blocked() { echo "$output" | jq -e '.decision == "block"' >/dev/null; }

@test "a continuation (stop_hook_active) is verified too: it blocks while failing and is silent once fixed" {
  touch "$R/FAIL"
  run stop; blocked; [ "$(runs)" -eq 1 ]
  echo 1 > "$R/n.txt"
  run stop true; [ "$status" -eq 0 ]; blocked; [ "$(runs)" -eq 2 ]
  rm "$R/FAIL"
  run stop true; [ -z "$output" ]; [ "$(runs)" -eq 3 ]
  [ -s "$USKN_STATE_DIR/sessions/sid/verified" ]
  [ ! -e "$USKN_STATE_DIR/sessions/sid/verify-blocks" ]
}

@test "at most 3 blocks in a turn: the 4th failing Stop ends the turn with a systemMessage" {
  touch "$R/FAIL"
  run stop; blocked
  for i in 2 3; do echo "$i" > "$R/n.txt"; run stop true; blocked; done
  echo 4 > "$R/n.txt"
  run stop true
  [ "$status" -eq 0 ]
  [ "$(runs)" -eq 4 ]
  echo "$output" | jq -e 'has("decision") | not' >/dev/null
  echo "$output" | jq -r '.systemMessage' | grep -q "make verify"
  echo "$output" | jq -r '.systemMessage' | grep -q "verify.log"
  echo "$output" | jq -r '.systemMessage' | grep -q "3"
}

@test "a new turn (stop_hook_active false) counts from zero again" {
  touch "$R/FAIL"
  run stop; blocked
  for i in 2 3 4; do echo "$i" > "$R/n.txt"; run stop true; done
  refute blocked
  echo 5 > "$R/n.txt"
  run stop false; blocked
}

@test "a continuation with the tree unchanged since the failure blocks again without rerunning verify" {
  touch "$R/FAIL"
  run stop; blocked; first="$(echo "$output" | jq -r '.reason')"
  run stop true; blocked; [ "$(runs)" -eq 1 ]
  [ "$(echo "$output" | jq -r '.reason')" = "$first" ]
}

@test "verify-fast in the Makefile is preferred over verify" {
  printf 'verify:\n\t@echo full >> runs.log\nverify-fast:\n\t@echo fast >> runs.log\n' > "$R/Makefile"
  ( cd "$R" && git commit -qam fast )
  printf '{"session_id":"sid2","cwd":"%s","hook_event_name":"SessionStart"}' "$R" | "$BASE"
  echo x > "$R/new.txt"
  run bash -c "printf '{\"session_id\":\"sid2\",\"cwd\":\"$R\",\"stop_hook_active\":false}' | '$SCRIPT'"
  [ -z "$output" ]
  [ "$(cat "$R/runs.log")" = fast ]
}

@test "verify runs at the git root of cwd, not at CLAUDE_PROJECT_DIR (a worktree)" {
  export CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/elsewhere"; mkdir -p "$CLAUDE_PROJECT_DIR"
  mkdir -p "$R/sub"; echo x > "$R/new.txt"
  run bash -c "printf '{\"session_id\":\"sid\",\"cwd\":\"$R/sub\",\"stop_hook_active\":false}' | '$SCRIPT'"
  [ -z "$output" ]
  [ "$(runs)" -eq 1 ]
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
  [ "$status" -eq 0 ]; [ -z "$output" ]
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
  [ ! -e "$USKN_STATE_DIR/sessions/sid/project" ]
  [ ! -e "$USKN_STATE_DIR/sessions/sid/started" ]
}

# ---- the confined environment (spec: verify-gate, confined-hook-sandbox). The plugin is copied into a checkout of
# its own with a confined marker; a fake sandbox-exec first on PATH logs its arguments and runs the command.
confined_gate() {
  CO="$BATS_TEST_TMPDIR/checkout"; mkdir -p "$CO/plugins"
  cp -R "$BATS_TEST_DIRNAME/../.." "$CO/plugins/uskn-harness"
  TOOLS="$BATS_TEST_TMPDIR/tools"; SECRETS="$BATS_TEST_TMPDIR/secrets"; mkdir -p "$TOOLS/bin" "$SECRETS"
  printf 'kind=confined\ntools=%s\nsecrets=%s\n' "$TOOLS" "$SECRETS" > "$CO/.uskn-environment"
  CSCRIPT="$CO/plugins/uskn-harness/hooks/scripts/verify-gate.sh"
  RULES="$(cd "$CO" && pwd -P)/plugins/uskn-harness/hooks/scripts/lib/confined.sb"
  SBLOG="$BATS_TEST_TMPDIR/sandbox-exec.log"; mkdir -p "$BATS_TEST_TMPDIR/sbx"
  cat > "$BATS_TEST_TMPDIR/sbx/sandbox-exec" <<SB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$SBLOG"
while [ \$# -gt 0 ]; do case "\$1" in -f | -D | -p) shift 2 ;; *) break ;; esac; done
exec "\$@"
SB
  chmod +x "$BATS_TEST_TMPDIR/sbx/sandbox-exec"
  export HOME="$BATS_TEST_TMPDIR/h"; mkdir -p "$HOME"
}
cstop() { printf '{"session_id":"sid","cwd":"%s","hook_event_name":"Stop","stop_hook_active":false}' "$R" | "$CSCRIPT"; }

@test "confined on macOS: the verify convention and the fingerprint's git run under the rules, with the shared tools on PATH" {
  confined_gate
  printf 'verify:\n\t@echo run >> runs.log\n\t@echo "$$PATH" > "%s/path.log"\n\t@echo verify-ok\n' "$BATS_TEST_TMPDIR" > "$R/Makefile"
  USKN_HARNESS_OS=Darwin PATH="$BATS_TEST_TMPDIR/sbx:$PATH" run cstop
  [ "$status" -eq 0 ]; [ -z "$output" ]; [ "$(runs)" -eq 1 ]
  [ -s "$USKN_STATE_DIR/sessions/sid/verified" ]
  grep -qxF -- "-f $RULES -D SECRETS=$SECRETS bash -c make verify" "$SBLOG"
  grep -qE -- "^-f $RULES -D SECRETS=$SECRETS git -C .*/repo status" "$SBLOG"
  [ "$(cut -d: -f1 "$BATS_TEST_TMPDIR/path.log")" = "$TOOLS/bin" ]
  refute grep -qF "$HOME/.local" "$BATS_TEST_TMPDIR/path.log"
}

@test "confined on macOS: a verify that fails under the rules blocks as before" {
  confined_gate
  touch "$R/FAIL"
  USKN_HARNESS_OS=Darwin PATH="$BATS_TEST_TMPDIR/sbx:$PATH" run cstop
  blocked
  echo "$output" | jq -r '.reason' | grep -q "expected 2 got 3"
  grep -qxF -- "-f $RULES -D SECRETS=$SECRETS bash -c make verify" "$SBLOG"
}

@test "confined without the rules (not macOS, or no sandbox-exec): verify does not run, a systemMessage says so" {
  confined_gate
  echo x > "$R/new.txt"
  USKN_HARNESS_OS=Linux PATH="$BATS_TEST_TMPDIR/sbx:$PATH" run cstop
  [ "$status" -eq 0 ]; [ "$(runs)" -eq 0 ]
  echo "$output" | jq -e 'has("decision") | not' >/dev/null
  echo "$output" | jq -r '.systemMessage' | grep -q "not verified"
  echo "$output" | jq -r '.systemMessage' | grep -q "sandbox-exec"
  [ ! -e "$SBLOG" ]
  P="$(path_without sandbox-exec)"
  USKN_HARNESS_OS=Darwin PATH="$P" run cstop
  [ "$(runs)" -eq 0 ]
  echo "$output" | jq -r '.systemMessage' | grep -q "not verified"
}
