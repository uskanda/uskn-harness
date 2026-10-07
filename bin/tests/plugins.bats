#!/usr/bin/env bats
# Tests for how bin/uskn-harness handles every plugin under plugins/ (spec: harness-sync, harness-doctor,
# claude-plugin-packaging). A fixture checkout carries the plugins, so the tests do not depend on which plugins the
# harness ships today. HOME and CLAUDE_CONFIG_DIR point into $BATS_TEST_TMPDIR; network steps are stubbed.

REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
CLI="$REPO/bin/uskn-harness"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  export USKN_HARNESS_STUB_NET=1
  export USKN_HARNESS_STUB_LOG="$BATS_TEST_TMPDIR/net.log"
  export XDG_STATE_HOME="$HOME/.local/state"; unset USKN_STATE_DIR
  mkdir -p "$HOME/.local/bin" "$CLAUDE_CONFIG_DIR/skills"
  : > "$USKN_HARNESS_STUB_LOG"
  SKILLS="$CLAUDE_CONFIG_DIR/skills"
  export PATH="$HOME/.local/bin:$PATH"
  printf '#!/bin/sh\necho "9.9.9 (Claude Code)"\n' > "$HOME/.local/bin/claude"; chmod +x "$HOME/.local/bin/claude"
  FX="$BATS_TEST_TMPDIR/fx"
  mkdir -p "$FX/skills/a/fine" "$FX/templates/user" "$FX/bin"
  printf -- '---\nname: fine\ndescription: x\n---\n' > "$FX/skills/a/fine/SKILL.md"
  cp "$REPO/deps.json" "$FX/deps.json"; cp "$CLI" "$FX/bin/uskn-harness"
  echo '<!-- managed by uskn-harness -->' > "$FX/templates/user/CLAUDE.md"
  plugin uskn-harness; plugin zz-extra
  export USKN_HARNESS_DIR="$FX"
}

plugin() { mkdir -p "$FX/plugins/$1/.claude-plugin"; printf '{"name": "%s"}\n' "$1" > "$FX/plugins/$1/.claude-plugin/plugin.json"; }
refute() { ! "$@"; }

@test "sync links every directory under plugins/ that has .claude-plugin/plugin.json" {
  mkdir -p "$FX/plugins/not-a-plugin"
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ "$(readlink "$SKILLS/uskn-harness")" = "$FX/plugins/uskn-harness" ]
  [ "$(readlink "$SKILLS/zz-extra")" = "$FX/plugins/zz-extra" ]
  [[ "$output" == *"created"*"plugin zz-extra"* ]] || false
  [ ! -e "$SKILLS/not-a-plugin" ]
}

@test "a real directory where a plugin link goes is a conflict and is left alone" {
  mkdir -p "$SKILLS/zz-extra"; echo mine > "$SKILLS/zz-extra/file"
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [[ "$output" == *"conflict"*"plugin zz-extra"* ]] || false
  [ "$(cat "$SKILLS/zz-extra/file")" = mine ]
}

@test "a skill named after a plugin aborts with exit 2 before any write" {
  plugin uskn-notify
  mkdir -p "$FX/skills/b/uskn-notify"
  printf -- '---\nname: uskn-notify\ndescription: x\n---\n' > "$FX/skills/b/uskn-notify/SKILL.md"
  run "$CLI" sync --no-pull
  [ "$status" -eq 2 ]
  [[ "$output" == *"reserved"*"uskn-notify"* ]] || false
  [ ! -e "$SKILLS/fine" ]
}

@test "sync --remove takes out the link of every plugin" {
  "$CLI" sync --no-pull >/dev/null
  run "$CLI" sync --remove
  [ "$status" -eq 0 ]
  [ ! -e "$SKILLS/uskn-harness" ]; [ ! -L "$SKILLS/uskn-harness" ]
  [ ! -e "$SKILLS/zz-extra" ]; [ ! -L "$SKILLS/zz-extra" ]
}

@test "doctor checks the link of every plugin" {
  "$CLI" sync --no-pull >/dev/null
  rm "$SKILLS/zz-extra"
  run "$CLI" doctor
  [[ "$output" == *"ok        plugin uskn-harness"* ]] || false
  [[ "$output" == *"warn      plugin zz-extra: missing"* ]] || false
}

@test "make verify-plugin validates every plugin under plugins/" {
  run grep -E 'plugins/\*|for p in' "$REPO/Makefile"
  [ "$status" -eq 0 ]
  refute grep -qE 'validate --strict plugins/uskn-harness( |;|$)' "$REPO/Makefile"
}
