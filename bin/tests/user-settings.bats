#!/usr/bin/env bats
# Tests for the user settings step of bin/uskn-harness (spec: user-settings, harness-doctor).
# HOME, CLAUDE_CONFIG_DIR and the state dir point into $BATS_TEST_TMPDIR; network steps are stubbed.

REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
CLI="$REPO/bin/uskn-harness"
FRAGMENT="$REPO/templates/user/settings.json"
SEED="$REPO/templates/user/settings-seed.json"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  export USKN_HARNESS_DIR="$REPO"
  export USKN_HARNESS_STUB_NET=1
  export USKN_HARNESS_STUB_LOG="$BATS_TEST_TMPDIR/net.log"
  export XDG_STATE_HOME="$HOME/.local/state"; unset USKN_STATE_DIR
  mkdir -p "$HOME/.local/bin" "$CLAUDE_CONFIG_DIR/skills"
  : > "$USKN_HARNESS_STUB_LOG"
  LIVE="$CLAUDE_CONFIG_DIR/settings.json"
  RECORD="$XDG_STATE_HOME/uskn-harness/settings-applied.json"
  OVERLAY="$HOME/.config/uskn-harness/settings.json"
  export PATH="$HOME/.local/bin:$PATH"
  printf '#!/bin/sh\necho "9.9.9 (Claude Code)"\n' > "$HOME/.local/bin/claude"; chmod +x "$HOME/.local/bin/claude"
}

# refute <command...>: fails when the command succeeds (a bare `! cmd` mid-test never fails it).
refute() { ! "$@"; }
live() { jq -r "$1" "$LIVE"; }
has_allow() { jq -e --arg e "$2" 'any(.permissions.allow[]?; . == $e)' "$1" >/dev/null; }
write_live() { mkdir -p "$(dirname "$LIVE")"; printf '%s\n' "$1" > "$LIVE"; }
write_record() { mkdir -p "$(dirname "$RECORD")"; printf '%s\n' "$1" > "$RECORD"; }
write_overlay() { mkdir -p "$(dirname "$OVERLAY")"; printf '%s\n' "$1" > "$OVERLAY"; }
settings_lines() { grep -E '^[a-z]+ +user settings' <<<"$output" || true; }

# ------------------------------------------------------------------ fragment

@test "the settings fragment is a JSON object" {
  run jq -e 'type == "object"' "$FRAGMENT"
  [ "$status" -eq 0 ]
}

@test "the settings fragment has neither hooks nor modelSettings" {
  run jq -r '[keys[] | select(. == "hooks" or . == "modelSettings")] | join(" ")' "$FRAGMENT"
  [ "$status" -eq 0 ]
  [ -z "$output" ] || { echo "the fragment must not carry: $output"; false; }
}

@test "the seed is a JSON object, the last settings.json the dotfiles rendered" {
  run jq -e 'type == "object" and has("hooks") and has("modelSettings")' "$SEED"
  [ "$status" -eq 0 ]
}

# ------------------------------------------------------------------ merge

@test "sync writes the composite when there is no live settings.json, and records it" {
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [[ "$(settings_lines)" == created* ]] || false
  [ "$(jq -S . "$LIVE")" = "$(jq -S . "$FRAGMENT")" ]
  [ "$(jq -S . "$RECORD")" = "$(jq -S . "$FRAGMENT")" ]
}

@test "a second sync leaves settings.json alone and reports ok" {
  "$CLI" sync --no-pull >/dev/null
  before="$(cksum < "$LIVE")"
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [[ "$(settings_lines)" == ok* ]] || false
  [ "$(cksum < "$LIVE")" = "$before" ]
}

@test "a key the fragment does not carry stays in settings.json" {
  write_live '{"feedbackSurveyState": {"lastShownTime": 1}}'
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ "$(live .feedbackSurveyState.lastShownTime)" = 1 ]
}

@test "a key the fragment carries is overwritten with the fragment's value and reported as updated" {
  "$CLI" sync --no-pull >/dev/null
  jq '.theme = "something-else"' "$LIVE" > "$LIVE.tmp" && mv "$LIVE.tmp" "$LIVE"
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ "$(live .theme)" = "$(jq -r .theme "$FRAGMENT")" ]
  [[ "$(settings_lines)" == updated* ]] || false
}

@test "permissions.allow is a set: an entry added on the machine stays next to the fragment's" {
  write_live '{"permissions": {"allow": ["Bash(make *)"]}}'
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  has_allow "$LIVE" 'Bash(make *)'
  has_allow "$LIVE" 'Bash(git *)'
  [ "$(jq -r '.permissions.allow[0]' "$LIVE")" = 'Bash(make *)' ]
  [ "$(jq '[.permissions.allow[] | select(. == "Bash(git *)")] | length' "$LIVE")" = 1 ]
}

# ------------------------------------------------------------------ three-way cleanup

@test "an allow entry the record has and the fragment dropped leaves settings.json; a local one stays" {
  write_record '{"permissions": {"allow": ["Bash(snap list *)"]}}'
  write_live '{"permissions": {"allow": ["Bash(snap list *)", "Bash(make *)"]}}'
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  refute has_allow "$LIVE" 'Bash(snap list *)'
  has_allow "$LIVE" 'Bash(make *)'
}

@test "a key the record has and the fragment dropped is removed, whatever its value on the machine" {
  write_record '{"spinnerTipsEnabled": false}'
  write_live '{"spinnerTipsEnabled": true, "verbose": true}'
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ "$(live 'has("spinnerTipsEnabled")')" = false ]
  [ "$(live .verbose)" = true ]
}

@test "without a record the seed counts as the last fragment: the dotfiles hooks and modelSettings go" {
  write_live "$(jq '.' "$SEED")"
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ "$(live 'has("hooks")')" = false ]
  [ "$(live 'has("modelSettings")')" = false ]
  [ "$(live 'has("extraKnownMarketplaces")')" = false ]
  refute has_allow "$LIVE" 'Bash(snap list *)'
  [ -f "$RECORD" ]
}

@test "the seed's machine-only allow entries stay when the machine overlay lists them" {
  write_live "$(jq '.' "$SEED")"
  write_overlay '{"permissions": {"allow": ["Bash(sudo pvs)"]}}'
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  has_allow "$LIVE" 'Bash(sudo pvs)'
}

@test "the seed's machine-only allow entries go when no machine overlay lists them" {
  write_live "$(jq '.' "$SEED")"
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  refute has_allow "$LIVE" 'Bash(sudo pvs)'
}

# ------------------------------------------------------------------ machine overlay

@test "the machine overlay goes on top of the fragment" {
  write_overlay '{"model": "sonnet"}'
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ "$(live .model)" = sonnet ]
  [ "$(jq -r .model "$RECORD")" = sonnet ]
}

@test "without a machine overlay none is created" {
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ ! -e "$OVERLAY" ]
}

# ------------------------------------------------------------------ effort

@test "sync removes the effort /effort wrote under modelSettings, and the fragment's effortLevel stays" {
  write_live '{"modelSettings": {"claude-opus-5-5": {"effortLevel": "low"}}}'
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ "$(live 'has("modelSettings")')" = false ]
  [ "$(live .effortLevel)" = "$(jq -r .effortLevel "$FRAGMENT")" ]
}

@test "only effortLevel leaves a model's entry; maxEffortLevel stays" {
  write_live '{"modelSettings": {"claude-opus-5-5": {"effortLevel": "low", "maxEffortLevel": "high"}}}'
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ "$(jq -c '.modelSettings' "$LIVE")" = '{"claude-opus-5-5":{"maxEffortLevel":"high"}}' ]
}

@test "sync writes nothing back: the fragment and the machine overlay keep their content" {
  write_overlay '{"model": "sonnet"}'
  write_live '{"model": "haiku", "modelSettings": {"claude-opus-5-5": {"effortLevel": "low"}}}'
  frag="$(cksum < "$FRAGMENT")"; over="$(cksum < "$OVERLAY")"
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ "$(cksum < "$FRAGMENT")" = "$frag" ]
  [ "$(cksum < "$OVERLAY")" = "$over" ]
}

# ------------------------------------------------------------------ unreadable files, modes

@test "an unreadable settings.json is a conflict: nothing is written and the exit code stays 0" {
  write_live '{"model": '
  before="$(cksum < "$LIVE")"
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [[ "$(settings_lines)" == conflict*"$LIVE"* ]] || false
  [ "$(cksum < "$LIVE")" = "$before" ]
  [ ! -e "$RECORD" ]
}

@test "an unreadable machine overlay is a conflict that names it" {
  write_overlay 'not json'
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [[ "$(settings_lines)" == conflict*"$OVERLAY"* ]] || false
  [ ! -e "$LIVE" ]
  [ ! -e "$RECORD" ]
}

@test "--dry-run plans the cleanup and writes neither settings.json nor the record" {
  write_live "$(jq '.' "$SEED")"
  before="$(cksum < "$LIVE")"
  run "$CLI" sync --no-pull --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"plan"*"user settings: remove hooks"* ]] || false
  [ "$(cksum < "$LIVE")" = "$before" ]
  [ ! -e "$RECORD" ]
}

@test "sync --tools touches neither settings.json nor the record" {
  run "$CLI" sync --tools
  [ "$status" -eq 0 ]
  [ ! -e "$LIVE" ]
  [ ! -e "$RECORD" ]
}

@test "sync --remove takes out what the record says the harness put in, keeps the rest, and drops the record" {
  "$CLI" sync --no-pull >/dev/null
  jq '.permissions.allow += ["Bash(make *)"]' "$LIVE" > "$LIVE.tmp" && mv "$LIVE.tmp" "$LIVE"
  run "$CLI" sync --remove
  [ "$status" -eq 0 ]
  [ "$(live 'has("model")')" = false ]
  [ "$(jq -c '.permissions.allow' "$LIVE")" = '["Bash(make *)"]' ]
  [ ! -e "$RECORD" ]
}

# ------------------------------------------------------------------ doctor

@test "doctor: user settings are ok right after sync, and the staleness opt-out comes from the fragment" {
  "$CLI" sync --no-pull >/dev/null
  run "$CLI" doctor
  [[ "$output" == *"ok        user settings"* ]] || false
  [[ "$output" == *"ok        IMPECCABLE_NO_STALENESS_CHECK=1"* ]] || false
}

@test "doctor: a modelSettings effort written by /effort is a warn that names the path and sync" {
  "$CLI" sync --no-pull >/dev/null
  jq '.modelSettings = {"claude-opus-5-5": {"effortLevel": "low"}}' "$LIVE" > "$LIVE.tmp" && mv "$LIVE.tmp" "$LIVE"
  before="$(cksum < "$LIVE")"
  run "$CLI" doctor
  [[ "$output" == *"warn      user settings"*"modelSettings"*"sync"* ]] || false
  [ "$(cksum < "$LIVE")" = "$before" ]
}

@test "doctor: an unreadable machine overlay is a warn that names it" {
  "$CLI" sync --no-pull >/dev/null
  write_overlay 'not json'
  run "$CLI" doctor
  [[ "$output" == *"warn      user settings"*"$OVERLAY"* ]] || false
}
