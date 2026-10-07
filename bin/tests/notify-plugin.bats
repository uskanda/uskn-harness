#!/usr/bin/env bats
# Tests for the uskn-notify plugin and what sync and doctor do for it (spec: notify-plugin, harness-doctor).
# HOME, CLAUDE_CONFIG_DIR and the state dir point into $BATS_TEST_TMPDIR; network and install steps are stubbed.

REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
CLI="$REPO/bin/uskn-harness"
PLUGIN="$REPO/plugins/uskn-notify"
COMMANDS="claude-notify claude-notify.ps1 claude-notify-hook claude-notify-nag claude-notify-daemon claude-notify-ntfy-sub install-voicevox-engine"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  export USKN_HARNESS_DIR="$REPO"
  export USKN_HARNESS_STUB_NET=1
  export USKN_HARNESS_STUB_LOG="$BATS_TEST_TMPDIR/net.log"
  export XDG_STATE_HOME="$HOME/.local/state"; unset USKN_STATE_DIR USKN_HARNESS_OS
  mkdir -p "$HOME/.local/bin" "$CLAUDE_CONFIG_DIR/skills"
  : > "$USKN_HARNESS_STUB_LOG"
  BIN="$HOME/.local/bin"
  AGENTS="$HOME/Library/LaunchAgents"
  RECORDS="$XDG_STATE_HOME/uskn-harness/notify-installed"
  export PATH="$HOME/.local/bin:$PATH"
  printf '#!/bin/sh\necho "9.9.9 (Claude Code)"\n' > "$BIN/claude"; chmod +x "$BIN/claude"
}

refute() { ! "$@"; }
sha() { if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | awk '{print $1}'; }
# agents_in_sourced_cli <os>: run ensure_notify_agents from the sourced script with run_step answering success,
# so the hash record is written without launchctl.
agents_in_sourced_cli() {
  run env USKN_HARNESS_OS="$1" bash -c "USKN_HARNESS_SOURCED=1 . '$CLI'; HARNESS='$REPO'; run_step() { shift; echo \"ran \$*\"; return 0; }; ensure_notify_agents"
}

# ------------------------------------------------------------------ the plugin itself

@test "the plugin carries its manifest, hooks.json and the seven commands" {
  [ "$(jq -r .name "$PLUGIN/.claude-plugin/plugin.json")" = uskn-notify ]
  for c in $COMMANDS; do [ -f "$PLUGIN/bin/$c" ] || { echo "missing $c"; false; }; done
}

@test "hooks.json calls claude-notify-hook from the plugin root on Notification, UserPromptSubmit and Stop" {
  run jq -r '.hooks | to_entries[] | "\(.key) \(.value[0].hooks[0].command)"' "$PLUGIN/hooks/hooks.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *'Notification "${CLAUDE_PLUGIN_ROOT}"/bin/claude-notify-hook notification'* ]] || false
  [[ "$output" == *'UserPromptSubmit "${CLAUDE_PLUGIN_ROOT}"/bin/claude-notify-hook stop'* ]] || false
  [[ "$output" == *'Stop "${CLAUDE_PLUGIN_ROOT}"/bin/claude-notify-hook done'* ]] || false
}

@test "make verify shellchecks the plugin's bash commands and leaves out the Python and PowerShell ones" {
  run bash -c "cd '$REPO' && printf 'include Makefile\nprint-scripts: ; @echo \$(SCRIPTS)\n' | make -s -f - print-scripts"
  [ "$status" -eq 0 ]
  [[ "$output" == *"plugins/uskn-notify/bin/claude-notify-hook"* ]] || false
  refute grep -q 'claude-notify-daemon' <<<"$output"
  refute grep -q 'claude-notify.ps1' <<<"$output"
}

# ------------------------------------------------------------------ commands in ~/.local/bin

@test "sync links every command of the plugin into ~/.local/bin, the PowerShell speaker next to claude-notify" {
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  for c in $COMMANDS; do [ "$(readlink "$BIN/$c")" = "$PLUGIN/bin/$c" ] || { echo "not linked: $c"; false; }; done
  [[ "$output" == *"created"*"notify command claude-notify.ps1"* ]] || false
}

@test "a second sync reports the command links as ok" {
  "$CLI" sync --no-pull >/dev/null
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok        notify command claude-notify-hook"* ]] || false
}

@test "a real file where a command link goes is a conflict, left alone, and sync still exits 0" {
  echo 'old copy' > "$BIN/claude-notify"
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [[ "$output" == *"conflict"*"notify command claude-notify:"* ]] || false
  [ "$(cat "$BIN/claude-notify")" = 'old copy' ]
}

@test "sync neither creates nor changes ~/.config/claude-notify/config.env" {
  run "$CLI" sync --no-pull
  [ ! -e "$HOME/.config/claude-notify/config.env" ]
  mkdir -p "$HOME/.config/claude-notify"; echo 'CLAUDE_NOTIFY_TOKEN="secret"' > "$HOME/.config/claude-notify/config.env"
  before="$(cksum < "$HOME/.config/claude-notify/config.env")"
  run "$CLI" sync --no-pull
  [ "$(cksum < "$HOME/.config/claude-notify/config.env")" = "$before" ]
}

@test "sync --remove takes out the command links and nothing else in ~/.local/bin" {
  "$CLI" sync --no-pull >/dev/null
  echo mine > "$BIN/mine"
  run "$CLI" sync --remove
  [ "$status" -eq 0 ]
  for c in $COMMANDS; do [ ! -L "$BIN/$c" ] || { echo "still linked: $c"; false; }; done
  [ "$(cat "$BIN/mine")" = mine ]
  [ -x "$BIN/claude" ]
}

# ------------------------------------------------------------------ LaunchAgents (macOS)

@test "macOS: an existing LaunchAgent with no recorded hash is installed again through ~/.local/bin" {
  mkdir -p "$AGENTS"; touch "$AGENTS/com.claude.notify-daemon.plist"
  USKN_HARNESS_OS=Darwin run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  grep -qF "$BIN/claude-notify-daemon install" "$USKN_HARNESS_STUB_LOG"
  refute grep -q 'claude-notify-ntfy-sub install' "$USKN_HARNESS_STUB_LOG"
}

@test "macOS: a successful install records the command's hash and is reported as updated" {
  mkdir -p "$AGENTS"; touch "$AGENTS/com.claude.notify-daemon.plist"
  agents_in_sourced_cli Darwin
  [ "$status" -eq 0 ]
  [[ "$output" == *"ran $BIN/claude-notify-daemon install"* ]] || false
  [[ "$output" == *"updated"*"LaunchAgent com.claude.notify-daemon"* ]] || false
  [ "$(cat "$RECORDS/com.claude.notify-daemon.sha256")" = "$(sha "$PLUGIN/bin/claude-notify-daemon")" ]
}

@test "macOS: an unchanged command is not installed again and is reported as ok" {
  mkdir -p "$AGENTS" "$RECORDS"; touch "$AGENTS/com.claude.notify-ntfy-sub.plist"
  sha "$PLUGIN/bin/claude-notify-ntfy-sub" > "$RECORDS/com.claude.notify-ntfy-sub.sha256"
  agents_in_sourced_cli Darwin
  [ "$status" -eq 0 ]
  refute grep -q 'ran ' <<<"$output"
  [[ "$output" == *"ok        LaunchAgent com.claude.notify-ntfy-sub"* ]] || false
}

@test "macOS: without a plist nothing is installed; sync never opts in on its own" {
  USKN_HARNESS_OS=Darwin run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  refute grep -q ' install$' "$USKN_HARNESS_STUB_LOG"
  [ ! -e "$AGENTS" ]
}

@test "Linux: the LaunchAgent step does not run and does not show up" {
  mkdir -p "$AGENTS"; touch "$AGENTS/com.claude.notify-daemon.plist"
  USKN_HARNESS_OS=Linux run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  refute grep -q 'LaunchAgent' <<<"$output"
  refute grep -q 'install$' "$USKN_HARNESS_STUB_LOG"
}

# ------------------------------------------------------------------ doctor

@test "doctor: linked commands are ok, a real file is a warn with its path" {
  "$CLI" sync --no-pull >/dev/null
  rm "$BIN/claude-notify-hook"; echo 'old copy' > "$BIN/claude-notify-hook"
  run "$CLI" doctor
  [[ "$output" == *"ok        notify command claude-notify"* ]] || false
  [[ "$output" == *"warn      notify command claude-notify-hook"*"$BIN/claude-notify-hook"* ]] || false
}
