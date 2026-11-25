#!/usr/bin/env bats
# Tests for the user settings step of bin/uskn-harness (spec: user-settings, harness-doctor).
# HOME, CLAUDE_CONFIG_DIR and the state dir point into $BATS_TEST_TMPDIR; network steps are stubbed.

bats_require_minimum_version 1.5.0
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
CLI="$REPO/bin/uskn-harness"
FRAGMENT="$REPO/templates/user/settings.json"
ADMIN="$REPO/templates/user/settings-admin.json"
CONFINED="$REPO/templates/user/settings-confined.json"
LINUX="$REPO/templates/user/settings-linux.json"
DARWIN="$REPO/templates/user/settings-darwin.json"
FRAGMENTS="$FRAGMENT $ADMIN $CONFINED $LINUX $DARWIN"
# The common fragment before it was split into five (task 3.1): the admin Linux composite must equal it.
BEFORE="$BATS_TEST_DIRNAME/fixtures/settings-before-split.json"
SEED="$REPO/templates/user/settings-seed.json"
LINUX_ONLY='Bash(apt-cache *)
Bash(systemctl is-enabled *)
Bash(systemctl is-active *)
Bash(lscpu)
Read(//sys/devices/system/cpu/**)
Read(//usr/lib/**)'
load fixtures/confined

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
# sets_sorted <file>: the JSON with sorted keys and every array sorted, so two composites compare as sets
sets_sorted() { jq -S 'walk(if type == "array" then sort else . end)' "$1"; }
# composite <admin|confined> <Linux|Darwin>: the composite sync records, with no machine overlay. The confined one
# comes from a marked copy of the repository.
composite() {
  local h="$REPO"
  if [ "$1" = confined ]; then
    h="$BATS_TEST_TMPDIR/co"; [ -d "$h" ] || confined_copy "$h"
    mark_confined "$h" "$BATS_TEST_TMPDIR/tools"
  fi
  rm -f "$RECORD"
  USKN_HARNESS_DIR="$h" USKN_HARNESS_OS="$2" "$CLI" sync --no-pull >/dev/null 2>&1 || true
  cat "$RECORD"
}

# ------------------------------------------------------------------ fragment

@test "the five settings fragments are JSON objects, and none carries hooks or modelSettings" {
  for f in $FRAGMENTS; do
    jq -e 'type == "object"' "$f" >/dev/null || { echo "not a JSON object: $f"; false; }
    bad="$(jq -r '[keys[] | select(. == "hooks" or . == "modelSettings")] | join(" ")' "$f")"
    [ -z "$bad" ] || { echo "$f must not carry: $bad"; false; }
  done
}

@test "the common fragment turns the sandbox on; the admin one never fails to start without it and keeps the retry" {
  [ "$(jq -r '.sandbox.enabled' "$FRAGMENT")" = true ]
  [ "$(jq -r '.sandbox.failIfUnavailable' "$ADMIN")" = false ]
  [ "$(jq -r '.sandbox.allowUnsandboxedCommands' "$ADMIN")" = true ]
  [ "$(jq -r '.sandbox | has("failIfUnavailable") or has("allowUnsandboxedCommands")' "$FRAGMENT")" = false ]
}

@test "the confined fragment fails without the sandbox and never retries outside it" {
  [ "$(jq -r '.sandbox.failIfUnavailable' "$CONFINED")" = true ] || { echo "sandbox.failIfUnavailable"; false; }
  [ "$(jq -r '.sandbox.allowUnsandboxedCommands' "$CONFINED")" = false ] || { echo "sandbox.allowUnsandboxedCommands"; false; }
}

@test "the confined fragment lets a -p session edit files: Edit and Write are allowed" {
  for e in Edit Write; do has_allow "$CONFINED" "$e" || { echo "missing: $e"; false; }; done
}

@test "the admin sandbox leaves the eleven well-known tools outside, git as a whole; no other fragment has the list" {
  for t in git gh glab docker mise claude uskn-harness uskn-loop chezmoi ssh scp; do
    jq -e --arg p "$t *" 'any(.sandbox.excludedCommands[]?; . == $p)' "$ADMIN" >/dev/null || { echo "missing: $t *"; false; }
  done
  run jq -r '.sandbox.excludedCommands[] | select(test("^git [a-z]+ \\*$") or test("allow-repo"))' "$ADMIN"
  [ -z "$output" ]
  for f in "$FRAGMENT" "$CONFINED" "$LINUX" "$DARWIN"; do
    [ "$(jq -r '.sandbox.excludedCommands // [] | length' "$f")" = 0 ] || { echo "$f has sandbox.excludedCommands"; false; }
  done
}

@test "execution whose effect cannot be read beforehand stays inside the sandbox" {
  for f in $FRAGMENTS; do
    run jq -r '.sandbox.excludedCommands[]? | select(test("^(npm|pnpm|npx|make|python3?|node|curl|bash|sh) "))' "$f"
    [ -z "$output" ] || { echo "$f: $output"; false; }
  done
}

@test "the sandbox may write caches, the admin one tool data too, but never the harness state" {
  for d in '~/.cache' '~/.npm' '~/.local/state'; do
    jq -e --arg d "$d" 'any(.sandbox.filesystem.allowWrite[]?; . == $d)' "$FRAGMENT" >/dev/null || { echo "missing: $d"; false; }
  done
  for d in '~/.local/share/mise' '~/.local/share/pnpm'; do
    jq -e --arg d "$d" 'any(.sandbox.filesystem.allowWrite[]?; . == $d)' "$ADMIN" >/dev/null || { echo "missing in admin: $d"; false; }
    refute jq -e --arg d "$d" 'any(.sandbox.filesystem.allowWrite[]?; . == $d)' "$FRAGMENT" >/dev/null
  done
  jq -e 'any(.sandbox.filesystem.denyWrite[]?; . == "~/.local/state/uskn-harness")' "$FRAGMENT" >/dev/null
  for f in $FRAGMENTS; do
    run jq -r '.sandbox.filesystem.allowWrite[]? | select(test("uskn-harness|chezmoi|repos|^~/?$"))' "$f"
    [ -z "$output" ] || { echo "$f: $output"; false; }
  done
}

@test "only the admin fragment opens Unix sockets and every host; no fragment names a host of its own" {
  [ "$(jq -r '.sandbox.network.allowAllUnixSockets' "$ADMIN")" = true ]
  has_allow "$ADMIN" 'WebFetch(domain:*)'
  for f in "$FRAGMENT" "$CONFINED" "$LINUX" "$DARWIN"; do
    [ "$(jq -r '.sandbox.network // {} | has("allowAllUnixSockets")' "$f")" = false ] || { echo "$f: allowAllUnixSockets"; false; }
    refute has_allow "$f" 'WebFetch(domain:*)'
  done
  for f in $FRAGMENTS; do
    [ "$(jq -r '.sandbox.network // {} | has("allowedDomains")' "$f")" = false ] || { echo "$f: allowedDomains"; false; }
  done
}

@test "the six Linux-only allow entries live in the Linux fragment and nowhere else" {
  while IFS= read -r e; do
    has_allow "$LINUX" "$e" || { echo "missing in linux: $e"; false; }
    for f in "$FRAGMENT" "$ADMIN" "$CONFINED" "$DARWIN"; do refute has_allow "$f" "$e" || { echo "$f has $e"; false; }; done
  done <<<"$LINUX_ONLY"
}

@test "remoteControlAtStartup and defaultMode auto belong to the admin fragment" {
  [ "$(jq -r '.remoteControlAtStartup' "$ADMIN")" = true ]
  [ "$(jq -r '.permissions.defaultMode' "$ADMIN")" = auto ]
  for f in "$FRAGMENT" "$CONFINED" "$LINUX" "$DARWIN"; do
    [ "$(jq -r 'has("remoteControlAtStartup") or (.permissions // {} | has("defaultMode"))' "$f")" = false ] || { echo "$f"; false; }
  done
}

@test "sandbox arrays are sets: what the machine adds survives sync next to the fragment" {
  write_overlay '{"sandbox":{"excludedCommands":["terraform *"],"filesystem":{"allowWrite":["~/.terraform.d"]}}}'
  "$CLI" sync --no-pull >/dev/null
  jq -e '.sandbox.excludedCommands | (index("terraform *") != null) and (index("git *") != null)' "$LIVE" >/dev/null
  jq -e '.sandbox.filesystem.allowWrite | (index("~/.terraform.d") != null) and (index("~/.npm") != null)' "$LIVE" >/dev/null
  run "$CLI" sync --no-pull
  jq -e '[.sandbox.excludedCommands[] | select(. == "terraform *")] | length == 1' "$LIVE" >/dev/null
}

@test "an element Claude Code's /sandbox put into live stays after sync" {
  write_live '{"sandbox":{"excludedCommands":["kubectl *"]}}'
  "$CLI" sync --no-pull >/dev/null
  jq -e '.sandbox.excludedCommands | (index("kubectl *") != null) and (index("gh *") != null)' "$LIVE" >/dev/null
}

@test "a host the machine allows survives sync next to what live already has" {
  write_live '{"sandbox":{"network":{"allowedDomains":["pkg.example.test"]}}}'
  write_overlay '{"sandbox":{"network":{"allowedDomains":["gl.example.test"]}}}'
  "$CLI" sync --no-pull >/dev/null
  jq -e '.sandbox.network.allowedDomains | (index("gl.example.test") != null) and (index("pkg.example.test") != null)' "$LIVE" >/dev/null
  [ "$(live '.sandbox.network.allowAllUnixSockets')" = true ]
  "$CLI" sync --no-pull >/dev/null
  jq -e '[.sandbox.network.allowedDomains[] | select(. == "gl.example.test")] | length == 1' "$LIVE" >/dev/null
}

# ------------------------------------------------------------------ composites

@test "composite: admin on Linux has the same keys and elements as the fragment before the split" {
  composite admin Linux > "$BATS_TEST_TMPDIR/c.json"
  [ "$(sets_sorted "$BATS_TEST_TMPDIR/c.json")" = "$(sets_sorted "$BEFORE")" ]
}

@test "composite: confined drops what loosens the sandbox and allows Edit and Write" {
  composite confined Linux > "$BATS_TEST_TMPDIR/c.json"
  c="$BATS_TEST_TMPDIR/c.json"
  [ "$(jq -r '.sandbox | has("excludedCommands")' "$c")" = false ]
  [ "$(jq -r '.sandbox.network // {} | has("allowAllUnixSockets")' "$c")" = false ]
  [ "$(jq -r '.sandbox.failIfUnavailable' "$c")" = true ]
  [ "$(jq -r '.sandbox.allowUnsandboxedCommands' "$c")" = false ]
  [ "$(jq -r 'has("remoteControlAtStartup") or (.permissions | has("defaultMode"))' "$c")" = false ]
  refute has_allow "$c" 'WebFetch(domain:*)'
  has_allow "$c" Edit
  has_allow "$c" Write
}

@test "composite: confined allowWrite has neither the mise nor the pnpm dir" {
  composite confined Darwin > "$BATS_TEST_TMPDIR/c.json"
  run jq -r '.sandbox.filesystem.allowWrite[]' "$BATS_TEST_TMPDIR/c.json"
  [[ "$output" == *"~/.npm"* ]] || false
  [[ "$output" != *"mise"* ]] || false
  [[ "$output" != *"pnpm"* ]] || false
}

@test "composite: macOS leaves out the six Linux-only allow entries; Linux has them" {
  composite admin Darwin > "$BATS_TEST_TMPDIR/mac.json"
  composite admin Linux > "$BATS_TEST_TMPDIR/linux.json"
  while IFS= read -r e; do
    refute has_allow "$BATS_TEST_TMPDIR/mac.json" "$e" || { echo "macOS has $e"; false; }
    has_allow "$BATS_TEST_TMPDIR/linux.json" "$e" || { echo "Linux lacks $e"; false; }
  done <<<"$LINUX_ONLY"
}

@test "the seed is a JSON object, the last settings.json the dotfiles rendered" {
  run jq -e 'type == "object" and has("hooks") and has("modelSettings")' "$SEED"
  [ "$status" -eq 0 ]
}

# ------------------------------------------------------------------ merge

@test "sync writes the composite when there is no live settings.json, and records it" {
  USKN_HARNESS_OS=Linux run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [[ "$(settings_lines)" == created* ]] || false
  [ "$(sets_sorted "$LIVE")" = "$(sets_sorted "$BEFORE")" ]
  [ "$(jq -S . "$RECORD")" = "$(jq -S . "$LIVE")" ]
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

# ------------------------------------------------------------------ confined environment (spec: user-settings)

# confined_checkout: a marked copy of the repository with a shared tools dir that matches deps.json; sets CO and TOOLS
confined_checkout() {
  CO="$BATS_TEST_TMPDIR/co"; TOOLS="$BATS_TEST_TMPDIR/tools"
  confined_copy "$CO"; shared_tools "$TOOLS"; mark_confined "$CO" "$TOOLS"
}
LOOSENING='{"model":"sonnet","permissions":{"defaultMode":"bypassPermissions","allow":["Bash(make *)","WebFetch","WebFetch(domain:*.example.test)","WebFetch(domain:docs.example.test)"]},
  "sandbox":{"enabled":false,"failIfUnavailable":false,"allowUnsandboxedCommands":true,"excludedCommands":["terraform *"],
  "network":{"allowedDomains":["gl.example.test"],"allowAllUnixSockets":true},"filesystem":{"allowWrite":["~/.terraform.d"],"denyWrite":["~/secret"]}}}'

@test "confined: sync leaves the overlay's loosening keys out of live, warns with their paths, and keeps the rest" {
  confined_checkout
  write_overlay "$LOOSENING"
  over="$(cksum < "$OVERLAY")"
  USKN_HARNESS_DIR="$CO" run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ "$(cksum < "$OVERLAY")" = "$over" ]
  [ "$(live .model)" = sonnet ]
  has_allow "$LIVE" 'Bash(make *)'
  has_allow "$LIVE" 'WebFetch(domain:docs.example.test)'
  refute has_allow "$LIVE" 'WebFetch'
  refute has_allow "$LIVE" 'WebFetch(domain:*.example.test)'
  [ "$(live '.sandbox | has("excludedCommands")')" = false ]
  [ "$(live '.sandbox.network // {} | has("allowedDomains") or has("allowAllUnixSockets")')" = false ]
  [ "$(live '.sandbox.enabled')" = true ]
  [ "$(live '.sandbox.failIfUnavailable')" = true ]
  [ "$(live '.sandbox.allowUnsandboxedCommands')" = false ]
  [ "$(live '.permissions | has("defaultMode")')" = false ]
  [ "$(live '.sandbox.filesystem.allowWrite | index("~/.terraform.d")')" = null ]
  [ "$(live '.sandbox.filesystem.denyWrite | index("~/secret") != null')" = true ]
  warn="$(grep -E '^warn +user settings' <<<"$output")"
  [ "$(grep -c . <<<"$warn")" -eq 1 ]
  for p in sandbox.excludedCommands sandbox.allowUnsandboxedCommands sandbox.network.allowedDomains \
           sandbox.network.allowAllUnixSockets sandbox.failIfUnavailable sandbox.enabled sandbox.filesystem.allowWrite \
           permissions.defaultMode 'permissions.allow[WebFetch]' 'permissions.allow[WebFetch(domain:*.example.test)]'; do
    [[ "$warn" == *"$p"* ]] || { echo "warn lacks $p: $warn"; false; }
  done
  [[ "$warn" != *"docs.example.test"* ]] || false
}

@test "confined: a value that keeps the sandbox closed is carried over without a warn" {
  confined_checkout
  write_overlay '{"sandbox":{"enabled":true,"failIfUnavailable":true}}'
  USKN_HARNESS_DIR="$CO" run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ -z "$(grep -E '^warn +user settings' <<<"$output")" ] || false
}

# ------------------------------------------------------------------ print-settings (spec: user-settings)

@test "print-settings prints the composite sync would apply and writes nothing" {
  write_overlay '{"model":"sonnet"}'
  before="$( (cd "$HOME" && find . | LC_ALL=C sort) )"
  USKN_HARNESS_OS=Linux run --separate-stderr "$CLI" print-settings
  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq -r .model)" = sonnet ]
  printf '%s' "$output" | jq '.model = "opus[1m]"' > "$BATS_TEST_TMPDIR/out.json"
  [ "$(sets_sorted "$BATS_TEST_TMPDIR/out.json")" = "$(sets_sorted "$BEFORE")" ]
  [ "$( (cd "$HOME" && find . | LC_ALL=C sort) )" = "$before" ]
  [ ! -e "$LIVE" ]
  [ ! -e "$RECORD" ]
}

@test "print-settings in the confined environment prints the confined composite, loosening keys left out" {
  confined_checkout
  write_overlay "$LOOSENING"
  "$CLI" sync --no-pull >/dev/null 2>&1 || true
  live_sum="$(cksum < "$LIVE")"; rec_sum="$(cksum < "$RECORD")"
  USKN_HARNESS_DIR="$CO" run --separate-stderr "$CLI" print-settings
  [ "$status" -eq 0 ]
  printf '%s' "$output" > "$BATS_TEST_TMPDIR/out.json"
  [ "$(jq -r '.sandbox | has("excludedCommands")' "$BATS_TEST_TMPDIR/out.json")" = false ]
  [ "$(jq -r '.model' "$BATS_TEST_TMPDIR/out.json")" = sonnet ]
  has_allow "$BATS_TEST_TMPDIR/out.json" Write
  [[ "$stderr" == *"sandbox.excludedCommands"* ]] || false
  [ "$(cksum < "$LIVE")" = "$live_sum" ]
  [ "$(cksum < "$RECORD")" = "$rec_sum" ]
}

@test "print-settings with an unreadable overlay prints nothing, names it on stderr, and exits 1" {
  write_overlay 'not json'
  run --separate-stderr "$CLI" print-settings
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"$OVERLAY"* ]] || false
}
