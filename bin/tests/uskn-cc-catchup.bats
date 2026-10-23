#!/usr/bin/env bats
# Tests for bin/uskn-cc-catchup and the cc-catchup skill it runs.
# Each test builds a bare origin under $BATS_TEST_TMPDIR and points USKN_CC_CATCHUP_URL at it, so the fresh clone
# stays local. Fake claude, gh, and crontab from fixtures/cc-catchup-bin come first on PATH.

REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
CLI="$REPO/bin/uskn-cc-catchup"
FAKES="$BATS_TEST_DIRNAME/fixtures/cc-catchup-bin"
SKILL="$REPO/skills/cc-catchup"

setup() {
  T="$BATS_TEST_TMPDIR"
  export FAKE_DIR="$T/fake"
  mkdir -p "$FAKE_DIR"
  export USKN_STATE_DIR="$T/state"
  export GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1
  : > "$GIT_CONFIG_GLOBAL"
  git config --global init.defaultBranch main
  git config --global user.name tester
  git config --global user.email tester@example.com
  export PATH="$FAKES:$PATH"
  export USKN_CC_CATCHUP_URL="$T/origin.git"
  export USKN_CC_CATCHUP_MONTH=2026-10
  STATE="$T/state/cc-catchup"
  git init -q --bare "$T/origin.git"
  git init -q "$T/seed"
  echo one > "$T/seed/a.txt"
  git -C "$T/seed" add -A && git -C "$T/seed" commit -qm one
  git -C "$T/seed" remote add origin "$T/origin.git"
  git -C "$T/seed" push -q origin main
}

# out <json>: what the agent returns as structured_output.
out() { printf '%s\n' "$1" > "$FAKE_DIR/claude.out"; }
one_proposal='{"summary": "s", "proposals": [{"title": "Drop the foo hook", "kind": "retire", "body": "reason and plan"}]}'
calls() { cat "$FAKE_DIR/claude.count" 2>/dev/null || echo 0; }
created() { find "$FAKE_DIR/created" -name '*.title' 2>/dev/null | wc -l | tr -d ' '; }

@test "uskn-cc-catchup with no arguments shows the usage and exits 2" {
  run "$CLI"
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage: uskn-cc-catchup run"* ]] || false
}

@test "an unknown option to run is a usage error" {
  run "$CLI" run --weekly
  [ "$status" -eq 2 ]
  [ "$(calls)" -eq 0 ]
}

# ---- run ------------------------------------------------------------------------------------------------------------

@test "run asks the latest Opus at effort high, in a fresh clone of origin, with read-only tools" {
  out '{"summary": "nothing", "proposals": []}'
  run "$CLI" run
  [ "$status" -eq 0 ]
  [ "$(cat "$FAKE_DIR/claude.cwd")" = "$STATE/clone" ]
  [ -f "$STATE/clone/a.txt" ]
  args="$(cat "$FAKE_DIR/claude.args")"
  grep -qx -- '--model' <<< "$args" && grep -qx opus <<< "$args"
  grep -qx -- '--effort' <<< "$args" && grep -qx high <<< "$args"
  grep -qx 'Read,Grep,Glob,WebFetch,WebSearch' <<< "$args"
  grep -qx -- '--json-schema' <<< "$args"
  grep -qx "$SKILL/SKILL.md" <<< "$args"
  ! grep -qE '^(Bash|Edit|Write)' <<< "$args"
}

@test "the prompt carries the question, the installed version, and the issues already filed" {
  out '{"summary": "nothing", "proposals": []}'
  run "$CLI" run
  [ "$status" -eq 0 ]
  p="$(cat "$FAKE_DIR/claude.prompt")"
  [[ "$p" == *"Claude Code側で十分にケアされており"* ]] || false
  [[ "$p" == *"9.9.9"* ]] || false
  [[ "$p" == *"issues.json"* ]] || false
  grep -q -- '--label cc-catchup --state all' "$FAKE_DIR/gh.log"
}

@test "the clone follows origin on the next run" {
  out '{"summary": "nothing", "proposals": []}'
  "$CLI" run
  echo two > "$T/seed/a.txt"
  git -C "$T/seed" commit -qam two && git -C "$T/seed" push -q origin main
  echo dirt > "$STATE/clone/stray.txt"
  USKN_CC_CATCHUP_MONTH=2026-11 run "$CLI" run
  [ "$status" -eq 0 ]
  [ "$(cat "$STATE/clone/a.txt")" = two ]
  [ ! -e "$STATE/clone/stray.txt" ]
}

@test "each proposal becomes an issue labelled cc-catchup, with the run noted at the end" {
  out '{"summary": "s", "proposals": [
    {"title": "Drop the foo hook", "kind": "retire", "body": "reason and plan"},
    {"title": "Rewrite the bar skill", "kind": "change", "body": "other reason"}]}'
  run "$CLI" run
  [ "$status" -eq 0 ]
  [ "$(created)" -eq 2 ]
  [ "$(cat "$FAKE_DIR/created/1.title")" = "Drop the foo hook" ]
  [ "$(cat "$FAKE_DIR/created/1.label")" = cc-catchup ]
  grep -q 'reason and plan' "$FAKE_DIR/created/1.body"
  grep -q 'uskn-cc-catchup' "$FAKE_DIR/created/1.body"
  grep -q '9.9.9' "$FAKE_DIR/created/1.body"
  grep -q 'label create cc-catchup' "$FAKE_DIR/gh.log"
  [[ "$output" == *"https://github.com/acme/harness/issues/101"* ]] || false
}

@test "a proposal whose title an issue already has, open or closed, is not filed again" {
  printf '%s\n' '[{"number": 7, "title": "drop the foo hook", "state": "CLOSED", "stateReason": "NOT_PLANNED"}]' \
    > "$FAKE_DIR/issues.json"
  out "$one_proposal"
  run "$CLI" run
  [ "$status" -eq 0 ]
  [ "$(created)" -eq 0 ]
  [[ "$output" == *"#7"* ]] || false
}

@test "--dry-run files nothing and records nothing" {
  out "$one_proposal"
  run "$CLI" run --dry-run
  [ "$status" -eq 0 ]
  [ "$(created)" -eq 0 ]
  ! grep -q 'label create' "$FAKE_DIR/gh.log"
  [[ "$output" == *"Drop the foo hook"* ]] || false
  [ ! -f "$STATE/last-run.json" ]
}

@test "a run without a valid answer fails, files nothing, and records no success" {
  run "$CLI" run
  [ "$status" -eq 1 ]
  [ "$(created)" -eq 0 ]
  [ ! -f "$STATE/last-run.json" ]
}

@test "a failed claude call fails the run" {
  out "$one_proposal"
  echo 3 > "$FAKE_DIR/claude.exit"
  run "$CLI" run
  [ "$status" -eq 1 ]
  [ "$(created)" -eq 0 ]
}

@test "a successful run records the month and the version, and the next prompt names them" {
  out '{"summary": "nothing", "proposals": []}'
  run "$CLI" run
  [ "$status" -eq 0 ]
  [ "$(jq -r .month "$STATE/last-run.json")" = 2026-10 ]
  [ "$(jq -r .claude_version "$STATE/last-run.json")" = "9.9.9 (Claude Code)" ]
  USKN_CC_CATCHUP_MONTH=2026-11 run "$CLI" run
  p="$(cat "$FAKE_DIR/claude.prompt")"
  [[ "$p" == *"previous run"*"2026-10"* ]] || false
}

# ---- --if-due --------------------------------------------------------------------------------------------------------

@test "--if-due runs once a month" {
  out '{"summary": "nothing", "proposals": []}'
  run "$CLI" run --if-due
  [ "$status" -eq 0 ] && [ "$(calls)" -eq 1 ]
  run "$CLI" run --if-due
  [ "$status" -eq 0 ] && [ "$(calls)" -eq 1 ]
  [ -z "$output" ]
  USKN_CC_CATCHUP_MONTH=2026-11 run "$CLI" run --if-due
  [ "$status" -eq 0 ] && [ "$(calls)" -eq 2 ]
}

@test "--if-due gives up for the month after three failed attempts" {
  for _ in 1 2 3; do run "$CLI" run --if-due; [ "$status" -eq 1 ]; done
  [ "$(calls)" -eq 3 ]
  run "$CLI" run --if-due
  [ "$status" -eq 0 ] && [ "$(calls)" -eq 3 ]
  USKN_CC_CATCHUP_MONTH=2026-11 run "$CLI" run --if-due
  [ "$(calls)" -eq 4 ]
}

@test "a run that finds another run in progress leaves it alone" {
  mkdir -p "$STATE/lock"
  out "$one_proposal"
  run "$CLI" run
  [ "$status" -eq 0 ]
  [ "$(calls)" -eq 0 ]
}

# ---- cron ------------------------------------------------------------------------------------------------------------

@test "install-cron adds one daily --if-due line and keeps the other entries" {
  printf '0 1 * * * other-job\n' > "$FAKE_DIR/crontab"
  run "$CLI" install-cron
  [ "$status" -eq 0 ]
  run "$CLI" install-cron
  [ "$status" -eq 0 ]
  grep -qx '0 1 \* \* \* other-job' "$FAKE_DIR/crontab"
  [ "$(grep -c 'uskn-cc-catchup run --if-due' "$FAKE_DIR/crontab")" -eq 1 ]
  line="$(grep 'run --if-due' "$FAKE_DIR/crontab")"
  [[ "$line" == "17 9 * * * "* ]] || false
  [[ "$line" == *".local/share/uskn-harness/bin/uskn-cc-catchup"* ]] || false
  [[ "$line" == *">> $STATE/cron.log 2>&1" ]] || false
}

@test "install-cron works on an empty crontab and puts --wrap in front of the command" {
  run "$CLI" install-cron --wrap '/opt/notify.sh "catchup"'
  [ "$status" -eq 0 ]
  line="$(grep 'run --if-due' "$FAKE_DIR/crontab")"
  [[ "$line" == *'/opt/notify.sh "catchup" '*'/bin/uskn-cc-catchup run --if-due'* ]] || false
}

@test "remove-cron removes only its own entry" {
  printf '0 1 * * * other-job\n' > "$FAKE_DIR/crontab"
  "$CLI" install-cron
  run "$CLI" remove-cron
  [ "$status" -eq 0 ]
  [ "$(cat "$FAKE_DIR/crontab")" = '0 1 * * * other-job' ]
}

# ---- the skill and the schema agree -------------------------------------------------------------------------------

@test "the schema the script passes is valid JSON and the skill names every field of it" {
  jq -e '.properties.proposals.items.properties' "$SKILL/proposals.schema.json" > /dev/null
  for f in $(jq -r '(.properties | keys[]), (.properties.proposals.items.properties | keys[])' "$SKILL/proposals.schema.json"); do
    grep -q "\`$f\`" "$SKILL/SKILL.md" || { echo "SKILL.md does not name $f"; false; }
  done
  grep -q 'cc-catchup' "$SKILL/SKILL.md"
}
