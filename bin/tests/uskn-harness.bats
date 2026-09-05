#!/usr/bin/env bats
# Tests for bin/uskn-harness (spec: harness-sync, harness-doctor, user-layer-instructions).
# HOME and CLAUDE_CONFIG_DIR point into $BATS_TEST_TMPDIR; network steps are stubbed and logged.

REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
CLI="$REPO/bin/uskn-harness"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  export USKN_HARNESS_DIR="$REPO"
  export USKN_HARNESS_STUB_NET=1
  export USKN_HARNESS_STUB_LOG="$BATS_TEST_TMPDIR/net.log"
  mkdir -p "$HOME/.local/bin" "$CLAUDE_CONFIG_DIR/skills"
  : > "$USKN_HARNESS_STUB_LOG"
  SKILLS="$CLAUDE_CONFIG_DIR/skills"
  STABLE="$HOME/.local/share/uskn-harness"
}

snapshot() { ( cd "$HOME" && find . -printf '%p %y %l\n' | sort ); }

@test "--help prints usage and exits 0" {
  run "$CLI" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"sync"* ]] && [[ "$output" == *"doctor"* ]]
}

@test "unknown command exits 2" {
  run "$CLI" bogus
  [ "$status" -eq 2 ]
}

@test "sync --dry-run writes nothing and lists planned operations" {
  before="$(snapshot)"
  run "$CLI" sync --dry-run
  [ "$status" -eq 0 ]
  [ "$(snapshot)" = "$before" ]
  [[ "$output" == *"plan"* ]]
  [[ "$output" == *"$SKILLS/commit"* ]]
  [ ! -e "$STABLE" ]
}

@test "sync on a fresh machine links everything and records network steps" {
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ -L "$STABLE" ] && [ "$(readlink -f "$STABLE")" = "$REPO" ]
  [ -L "$HOME/.local/bin/uskn-harness" ] && [ "$(readlink -f "$HOME/.local/bin/uskn-harness")" = "$REPO/bin/uskn-harness" ]
  [ -L "$SKILLS/commit" ] && [ "$(readlink -f "$SKILLS/commit")" = "$REPO/skills/git/commit" ]
  [ -L "$SKILLS/pr" ] && [ -L "$SKILLS/mr-qa" ]
  [ -L "$SKILLS/uskn-harness" ] && [ "$(readlink -f "$SKILLS/uskn-harness")" = "$REPO/plugins/uskn-harness" ]
  [ -f "$CLAUDE_CONFIG_DIR/CLAUDE.md" ] && head -1 "$CLAUDE_CONFIG_DIR/CLAUDE.md" | grep -q "managed by uskn-harness"
  grep -q "mise use -g node@24" "$USKN_HARNESS_STUB_LOG"
  grep -q "openspec@1.12.0" "$USKN_HARNESS_STUB_LOG"
  grep -q "skills@latest add mattpocock/skills --skill grilling" "$USKN_HARNESS_STUB_LOG"
  [[ "$output" == *"created"* ]]
}

@test "second sync changes nothing and reports ok" {
  "$CLI" sync >/dev/null
  before="$(snapshot)"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ "$(snapshot)" = "$before" ]
  [[ "$output" != *"created"* ]]
  [[ "$output" == *"ok"* ]]
}

@test "existing real directory with a skill name is a conflict, left untouched, exit 0" {
  mkdir -p "$SKILLS/commit" && echo old > "$SKILLS/commit/SKILL.md"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"conflict"*"commit"* ]]
  [ ! -L "$SKILLS/commit" ] && [ "$(cat "$SKILLS/commit/SKILL.md")" = old ]
  [ -L "$SKILLS/pr" ]
}

@test "symlink pointing outside the harness is a conflict" {
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere/pr" && ln -s "$BATS_TEST_TMPDIR/elsewhere/pr" "$SKILLS/pr"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"conflict"*"pr"* ]]
  [ "$(readlink "$SKILLS/pr")" = "$BATS_TEST_TMPDIR/elsewhere/pr" ]
}

@test "dangling or moved symlink into the harness is updated" {
  ln -s "$REPO/skills/old-location/pr" "$SKILLS/pr"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"updated"*"pr"* ]]
  [ "$(readlink -f "$SKILLS/pr")" = "$REPO/skills/git/pr" ]
}

@test "duplicate skill names abort before any write" {
  fx="$BATS_TEST_TMPDIR/fx"; mkdir -p "$fx/skills/a/dup" "$fx/skills/b/dup" "$fx/plugins/uskn-harness" "$fx/templates/user" "$fx/bin"
  printf -- '---\nname: dup\ndescription: x\n---\n' | tee "$fx/skills/a/dup/SKILL.md" > "$fx/skills/b/dup/SKILL.md"
  cp "$REPO/deps.json" "$fx/deps.json"; cp "$CLI" "$fx/bin/uskn-harness"; echo '<!-- managed by uskn-harness -->' > "$fx/templates/user/CLAUDE.md"
  before="$(snapshot)"
  USKN_HARNESS_DIR="$fx" run "$CLI" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"duplicate"* ]]
  [ "$(snapshot)" = "$before" ]
}

@test "a hand-written ~/.claude/CLAUDE.md is preserved and reported as conflict" {
  echo "# mine" > "$CLAUDE_CONFIG_DIR/CLAUDE.md"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"conflict"*"CLAUDE.md"* ]]
  [ "$(cat "$CLAUDE_CONFIG_DIR/CLAUDE.md")" = "# mine" ]
}

@test "a managed ~/.claude/CLAUDE.md is refreshed when the template changes" {
  "$CLI" sync >/dev/null
  echo "stale" >> "$CLAUDE_CONFIG_DIR/CLAUDE.md"
  run "$CLI" sync
  [[ "$output" == *"updated"*"CLAUDE.md"* ]]
  cmp -s "$CLAUDE_CONFIG_DIR/CLAUDE.md" "$REPO/templates/user/CLAUDE.md"
}

@test "third-party skill already present is not reinstalled" {
  mkdir -p "$SKILLS/grilling" && touch "$SKILLS/grilling/SKILL.md"
  run "$CLI" sync
  ! grep -q "grilling" "$USKN_HARNESS_STUB_LOG"
}

@test "sync --remove deletes harness symlinks only" {
  "$CLI" sync >/dev/null
  mkdir -p "$SKILLS/keepme" && echo "# mine" > "$SKILLS/keepme/SKILL.md"
  run "$CLI" sync --remove
  [ "$status" -eq 0 ]
  [ ! -e "$SKILLS/commit" ] && [ ! -e "$SKILLS/uskn-harness" ] && [ ! -e "$HOME/.local/bin/uskn-harness" ] && [ ! -e "$STABLE" ]
  [ -d "$SKILLS/keepme" ]
  [ ! -e "$CLAUDE_CONFIG_DIR/CLAUDE.md" ]
}

@test "doctor after sync exits 0 and writes nothing" {
  "$CLI" sync >/dev/null
  before="$(snapshot)"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [ "$(snapshot)" = "$before" ]
  [ "$(printf '%s\n' "$output" | grep -c '^fail')" -eq 0 ]
}

@test "doctor: symlink pointing elsewhere is fail, exit 1" {
  "$CLI" sync >/dev/null
  rm "$SKILLS/pr"; mkdir -p "$BATS_TEST_TMPDIR/elsewhere/pr"; ln -s "$BATS_TEST_TMPDIR/elsewhere/pr" "$SKILLS/pr"
  run "$CLI" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"fail"*"pr"* ]]
}

@test "doctor: real-directory conflict alone is warn, exit 0" {
  mkdir -p "$SKILLS/commit" && echo old > "$SKILLS/commit/SKILL.md"
  "$CLI" sync >/dev/null
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"commit"* ]]
}

@test "doctor before sync reports missing items as warn and the stable path as warn" {
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"* ]]
}

@test "templates/user/CLAUDE.md is under 60 lines and starts with the marker" {
  [ "$(wc -l < "$REPO/templates/user/CLAUDE.md")" -le 60 ]
  head -1 "$REPO/templates/user/CLAUDE.md" | grep -q "managed by uskn-harness"
}
