#!/usr/bin/env bats
# Tests for the third-party skills of bin/uskn-harness and for their pins in deps.json
# (spec: harness-sync, harness-doctor, ci-verify). HOME, CLAUDE_CONFIG_DIR, and the skills CLI lock file live in
# $BATS_TEST_TMPDIR. Network steps are stubbed and logged, except where a test puts fake curl / mise / npx on PATH.

REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
CLI="$REPO/bin/uskn-harness"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  export USKN_HARNESS_DIR="$REPO"
  export USKN_HARNESS_STUB_NET=1
  export USKN_HARNESS_STUB_LOG="$BATS_TEST_TMPDIR/net.log"
  unset XDG_STATE_HOME IMPECCABLE_NO_STALENESS_CHECK
  mkdir -p "$HOME/.local/bin" "$CLAUDE_CONFIG_DIR/skills"
  : > "$USKN_HARNESS_STUB_LOG"
  SKILLS="$CLAUDE_CONFIG_DIR/skills"
  AGENTS="$CLAUDE_CONFIG_DIR/agents"
  LOCK="$HOME/.agents/.skill-lock.json"
}

# refute <command...>: fails when the command succeeds (a bare `! cmd` mid-test never fails it).
refute() { ! "$@"; }
# dep <jq path>: a value from deps.json, so a pin bump needs no test edit.
dep() { jq -r "$1" "$REPO/deps.json"; }

# ---------------------------------------------------------------- pins (spec: harness-sync, ci-verify)

@test "every ref in deps.json is a tag or a full 40-character commit SHA" {
  bad=0
  while IFS=$'\t' read -r where ref; do
    if [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then continue; fi
    if [[ "$ref" =~ ^[0-9a-f]+$ ]]; then echo "$where: '$ref' is a short SHA"; bad=1; continue; fi
    [[ "$ref" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ ]] || { echo "$where: '$ref' is neither a tag nor a SHA"; bad=1; }
  done < <(jq -r 'path(.. | select(objects | has("ref"))) as $p | [($p | map(tostring) | join(".")), (getpath($p).ref)] | @tsv' "$REPO/deps.json")
  [ "$bad" -eq 0 ]
}

@test "the skills CLI is pinned to a fixed version, not latest" {
  [[ "$(dep .clis.skills.version)" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "every reference skill sync installs says how (via) and pins a source and a ref; none keeps an install string" {
  [ "$(jq '[.skills[] | select(has("install"))] | length' "$REPO/deps.json")" -eq 0 ]
  [ "$(jq '[.skills[] | select(.via == "skills") | select((.source | type) != "string" or (.ref | type) != "string")] | length' "$REPO/deps.json")" -eq 0 ]
  [ "$(jq '[.skills[] | select(.via == "skills")] | length' "$REPO/deps.json")" -ge 6 ]
}

@test "impeccable pins the skill release (ref = skill-v<version>), its sha256, the CLI version, and the agents to remove" {
  [ "$(dep .skills.impeccable.via)" = impeccable ]
  [ "$(dep .skills.impeccable.ref)" = "skill-v$(dep .skills.impeccable.version)" ]
  [[ "$(dep .skills.impeccable.sha256)" =~ ^[0-9a-f]{64}$ ]]
  [ -n "$(dep .skills.impeccable.asset | grep -v '^null$')" ]
  [ "$(dep .skills.impeccable.cli.package)" = impeccable ]
  [[ "$(dep .skills.impeccable.cli.version)" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
  [ "$(jq '.skills.impeccable.remove_agents | length' "$REPO/deps.json")" -eq 4 ]
}

@test "CI installs Claude Code without a version" {
  grep -qE 'npm install -g @anthropic-ai/claude-code([[:space:]]|$)' "$REPO/.github/workflows/verify.yml"
  refute grep -qE '@anthropic-ai/claude-code@' "$REPO/.github/workflows/verify.yml"
}

# ---------------------------------------------------------------- helpers for the install tests

# via_skills: the names of the entries sync installs through the skills CLI.
via_skills() { jq -r '.skills | to_entries[] | select(.value.mode == "reference" and .value.via == "skills") | .key' "$REPO/deps.json"; }
# install_line <name>: the skills CLI command sync runs for <name>, as the stub log records it (quotes gone).
install_line() {
  printf 'npx -y skills@%s add %s#%s@%s -g -a claude-code -y' \
    "$(dep .clis.skills.version)" "$(dep ".skills[\"$1\"].source")" "$(dep ".skills[\"$1\"].ref")" "$1"
}
# present <name>: a skill directory under ~/.claude/skills.
present() { mkdir -p "$SKILLS/$1"; printf -- '---\nname: %s\ndescription: x\n---\n' "$1" > "$SKILLS/$1/SKILL.md"; }
# lock <name> [ref]: record <name> in the skills CLI lock file ($LOCK), with a ref only when one is given, as the
# CLI does. Without a ref the entry looks like the ones installed before this harness pinned refs.
lock() {
  local out
  mkdir -p "$(dirname "$LOCK")"
  [ -f "$LOCK" ] || printf '{"version":3,"skills":{},"dismissed":{}}\n' > "$LOCK"
  out="$(jq --arg n "$1" --arg r "${2:-}" --arg s "$(dep ".skills[\"$1\"].source // \"x/y\"")" \
    '.skills[$n] = ({source: $s, sourceType: "github", skillPath: "SKILL.md"} + (if $r == "" then {} else {ref: $r} end))' "$LOCK")"
  printf '%s\n' "$out" > "$LOCK"
}
# unlock <name>: remove <name> from the lock file.
unlock() { local out; out="$(jq --arg n "$1" 'del(.skills[$n])' "$LOCK")"; printf '%s\n' "$out" > "$LOCK"; }
# impeccable_at <version|->: an installed impeccable skill whose SKILL.md says <version> ("-": no version line).
impeccable_at() {
  mkdir -p "$SKILLS/impeccable"
  { echo '---'; echo 'name: impeccable'; echo 'description: x'; [ "$1" = - ] || echo "version: $1"; echo '---'; } > "$SKILLS/impeccable/SKILL.md"
}
# pinned_all: every via:skills entry present and locked at its pin, and impeccable at its pinned version.
pinned_all() {
  local n
  for n in $(via_skills); do present "$n"; lock "$n" "$(dep ".skills[\"$n\"].ref")"; done
  impeccable_at "$(dep .skills.impeccable.version)"
}
# fake_tools: curl, mise, and npx stand-ins at the front of PATH (from tests/fixtures). mise runs what follows
# `--`; npx appends its arguments and IMPECCABLE_BUNDLE_PATH to $FAKE_LOG and exits with $FAKE_NPX_RC; as the
# Impeccable CLI it also writes the skill at $FAKE_IMPECCABLE_VERSION and the four agents. curl copies $FAKE_ZIP.
fake_tools() {
  FAKE="$BATS_TEST_DIRNAME/fixtures/fake-bin"
  export FAKE_LOG="$BATS_TEST_TMPDIR/fake.log"
  : > "$FAKE_LOG"
}
# sourced <shell code>: run the script's functions for real (no stub), with the fake tools first on PATH.
# HARNESS_DIR swaps in another checkout, for a deps.json whose sha256 matches a test zip.
sourced() { run env USKN_HARNESS_STUB_NET=0 PATH="$FAKE:$PATH" bash -c "USKN_HARNESS_SOURCED=1 . '$CLI'; HARNESS='${HARNESS_DIR:-$REPO}'; $*"; }
# test_zip: a stand-in release asset in $FAKE_ZIP, its sha256 in $ZIP_SHA.
test_zip() {
  export FAKE_ZIP="$BATS_TEST_TMPDIR/universal.zip"
  printf 'not really a zip\n' > "$FAKE_ZIP"
  ZIP_SHA="$(sha256sum "$FAKE_ZIP" | cut -d' ' -f1)"
}
# impeccable_line: what sync logs for the pinned Impeccable install under the stub.
impeccable_line() {
  printf 'impeccable_install https://github.com/%s/releases/download/%s/%s %s impeccable@%s' \
    "$(dep .skills.impeccable.source)" "$(dep .skills.impeccable.ref)" "$(dep .skills.impeccable.asset)" \
    "$(dep .skills.impeccable.sha256)" "$(dep .skills.impeccable.cli.version)"
}
# impeccable_agents: the agent files deps.json says to remove, one path per line.
impeccable_agents() { jq -r '.skills.impeccable.remove_agents[]' "$REPO/deps.json" | sed "s#^#$AGENTS/#; s#\$#.md#"; }

# ---------------------------------------------------------------- skills CLI entries (spec: harness-sync)

@test "sync installs each missing skill as <source>#<ref>@<name> with the pinned skills CLI" {
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  for n in $(via_skills); do grep -qF "$(install_line "$n")" "$USKN_HARNESS_STUB_LOG"; done
  refute grep -q "skills@latest" "$USKN_HARNESS_STUB_LOG"
}

@test "a skill whose lock ref matches the pin is ok and not reinstalled" {
  pinned_all
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  refute grep -qF "skills@" "$USKN_HARNESS_STUB_LOG"
  [[ "$output" == *"ok"*"third-party grilling"* ]]
}

@test "a skill whose lock ref differs from the pin, or has no ref, is reinstalled" {
  pinned_all
  lock grilling 0000000000000000000000000000000000000000
  lock humanizer
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  grep -qF "$(install_line grilling)" "$USKN_HARNESS_STUB_LOG"
  grep -qF "$(install_line humanizer)" "$USKN_HARNESS_STUB_LOG"
  refute grep -qF "@handoff " "$USKN_HARNESS_STUB_LOG"
}

@test "a reinstall that succeeds is reported updated, a first install created, a failed one fail" {
  pinned_all; fake_tools
  lock grilling
  rm -rf "$SKILLS/handoff"
  sourced ensure_third_party
  [ "$status" -eq 0 ]
  [[ "$output" == *"updated"*"third-party grilling"* ]]
  [[ "$output" == *"created"*"third-party handoff"* ]]
  grep -qF "$(install_line grilling)" "$FAKE_LOG"
  FAKE_NPX_RC=1 sourced 'ensure_third_party; echo "FAILS=$FAILS"'
  [[ "$output" == *"fail"*"third-party grilling"* ]]
  [[ "$output" == *"FAILS=2"* ]]
}

@test "a skill directory the lock does not know is a conflict, left untouched" {
  pinned_all
  unlock grilling
  echo "# mine" > "$SKILLS/grilling/SKILL.md"
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [[ "$output" == *"conflict"*"third-party grilling"* ]]
  refute grep -qF "@grilling " "$USKN_HARNESS_STUB_LOG"
  [ "$(cat "$SKILLS/grilling/SKILL.md")" = "# mine" ]
}

@test "with XDG_STATE_HOME set, the lock is read from \$XDG_STATE_HOME/skills" {
  pinned_all
  export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
  run "$CLI" sync --no-pull
  [[ "$output" == *"conflict"*"third-party grilling"* ]]
  mkdir -p "$XDG_STATE_HOME/skills" && mv "$LOCK" "$XDG_STATE_HOME/skills/.skill-lock.json"
  : > "$USKN_HARNESS_STUB_LOG"
  run "$CLI" sync --no-pull
  [[ "$output" == *"ok"*"third-party grilling"* ]]
  refute grep -qF "skills@" "$USKN_HARNESS_STUB_LOG"
}

@test "sync --dry-run plans a reinstall and writes nothing" {
  pinned_all
  lock grilling
  before="$( cd "$HOME" && find . -printf '%p %y %s\n' | sort )"
  run "$CLI" sync --dry-run --no-pull
  [ "$status" -eq 0 ]
  [[ "$output" == *"plan"*"@grilling"* ]]
  [ "$( cd "$HOME" && find . -printf '%p %y %s\n' | sort )" = "$before" ]
}

# ---------------------------------------------------------------- impeccable (spec: harness-sync)

@test "sync installs impeccable from the pinned release asset, its sha256, and the pinned CLI" {
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  grep -qF "$(impeccable_line)" "$USKN_HARNESS_STUB_LOG"
}

@test "impeccable at the pinned version is ok: nothing is downloaded or installed" {
  pinned_all
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  refute grep -q "impeccable_install" "$USKN_HARNESS_STUB_LOG"
  [[ "$output" == *"ok"*"third-party impeccable $(dep .skills.impeccable.version)"* ]]
}

@test "an older impeccable is reinstalled from the pinned release" {
  pinned_all
  impeccable_at 4.2.0
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  grep -qF "$(impeccable_line)" "$USKN_HARNESS_STUB_LOG"
}

@test "an impeccable SKILL.md without a version is a conflict, left untouched" {
  pinned_all
  impeccable_at -
  before="$(cat "$SKILLS/impeccable/SKILL.md")"
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [[ "$output" == *"conflict"*"third-party impeccable"* ]]
  refute grep -q "impeccable_install" "$USKN_HARNESS_STUB_LOG"
  [ "$(cat "$SKILLS/impeccable/SKILL.md")" = "$before" ]
}

@test "impeccable_install downloads the asset, checks its sha256, and runs the CLI with IMPECCABLE_BUNDLE_PATH" {
  fake_tools; test_zip
  FAKE_IMPECCABLE_VERSION=9.9.9 sourced "impeccable_install https://example.invalid/skill-v9.9.9/universal.zip $ZIP_SHA impeccable@4.1.0"
  [ "$status" -eq 0 ]
  grep -qF "curl https://example.invalid/skill-v9.9.9/universal.zip" "$FAKE_LOG"
  grep -qE "^npx -y impeccable@4\.1\.0 install -y --providers=claude --scope=global --no-hooks \| bundle=/.+/universal\.zip$" "$FAKE_LOG"
  grep -qx "version: 9.9.9" "$SKILLS/impeccable/SKILL.md"
}

@test "impeccable_install stops before the CLI when the sha256 differs" {
  fake_tools; test_zip
  sourced "impeccable_install https://example.invalid/skill-v9.9.9/universal.zip $(printf '0%.0s' {1..64}) impeccable@4.1.0"
  [ "$status" -ne 0 ]
  [[ "$output" == *"sha256"* ]]
  refute grep -q "^npx" "$FAKE_LOG"
  [ ! -e "$SKILLS/impeccable" ]
}

@test "the impeccable step: a sha256 mismatch is a fail and installs nothing; a match updates and reports the version" {
  fake_tools; test_zip
  pinned_all; impeccable_at 4.2.0
  sourced 'ensure_third_party; echo "FAILS=$FAILS"'
  [[ "$output" == *"fail"*"third-party impeccable"* ]]
  [[ "$output" == *"FAILS=1"* ]]
  refute grep -q "^npx" "$FAKE_LOG"
  grep -qx "version: 4.2.0" "$SKILLS/impeccable/SKILL.md"
  HARNESS_DIR="$BATS_TEST_TMPDIR/fx"; mkdir -p "$HARNESS_DIR"
  jq --arg s "$ZIP_SHA" '.skills.impeccable.sha256 = $s' "$REPO/deps.json" > "$HARNESS_DIR/deps.json"
  FAKE_IMPECCABLE_VERSION="$(dep .skills.impeccable.version)" sourced 'ensure_third_party; echo "FAILS=$FAILS"'
  [[ "$output" == *"updated"*"third-party impeccable 4.2.0 -> $(dep .skills.impeccable.version)"* ]]
  [[ "$output" == *"FAILS=0"* ]]
  grep -qx "version: $(dep .skills.impeccable.version)" "$SKILLS/impeccable/SKILL.md"
}

# ---------------------------------------------------------------- impeccable agents (spec: harness-sync)

@test "after the impeccable step the listed agents are removed; other agents stay" {
  pinned_all
  mkdir -p "$AGENTS"
  impeccable_agents | while read -r f; do echo x > "$f"; done
  echo mine > "$AGENTS/my-agent.md"; echo mine > "$AGENTS/impeccable-mine.md"
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | grep -c '^removed .*impeccable')" -eq 4 ]
  impeccable_agents | while read -r f; do [ ! -e "$f" ]; done
  [ -f "$AGENTS/my-agent.md" ]; [ -f "$AGENTS/impeccable-mine.md" ]
  run "$CLI" sync --no-pull
  [ "$status" -eq 0 ]
  [[ "$output" != *"removed"* ]]
}

@test "an impeccable install through the CLI ends without its agents" {
  fake_tools; test_zip
  pinned_all; rm -rf "$SKILLS/impeccable"
  HARNESS_DIR="$BATS_TEST_TMPDIR/fx"; mkdir -p "$HARNESS_DIR"
  jq --arg s "$ZIP_SHA" '.skills.impeccable.sha256 = $s' "$REPO/deps.json" > "$HARNESS_DIR/deps.json"
  FAKE_IMPECCABLE_VERSION="$(dep .skills.impeccable.version)" sourced ensure_third_party
  [[ "$output" == *"created"*"third-party impeccable"* ]]
  impeccable_agents | while read -r f; do [ ! -e "$f" ]; done
  [ -d "$AGENTS" ]
}

@test "the agents stay when impeccable is a conflict, and --dry-run only plans their removal" {
  pinned_all; impeccable_at -
  mkdir -p "$AGENTS"; impeccable_agents | while read -r f; do echo x > "$f"; done
  run "$CLI" sync --no-pull
  impeccable_agents | while read -r f; do [ -f "$f" ]; done
  impeccable_at "$(dep .skills.impeccable.version)"
  run "$CLI" sync --dry-run --no-pull
  [ "$status" -eq 0 ]
  [[ "$output" == *"plan"*"remove"*"impeccable-documenter.md"* ]]
  impeccable_agents | while read -r f; do [ -f "$f" ]; done
}

# ---------------------------------------------------------------- doctor (spec: harness-doctor)

# staleness_off: the user settings env that silences Impeccable's staleness check.
staleness_off() { printf '{"env":{"IMPECCABLE_NO_STALENESS_CHECK":"1"}}\n' > "$CLAUDE_CONFIG_DIR/settings.json"; }

@test "doctor: everything at its pin is ok, and doctor writes nothing" {
  pinned_all; staleness_off
  before="$( cd "$HOME" && find . -printf '%p %y %s\n' | sort )"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  refute grep -qE '^warn .*(third-party|impeccable|IMPECCABLE)' <<<"$output"
  [[ "$output" == *"ok"*"third-party grilling $(dep .skills.grilling.ref | cut -c1-12)"* ]]
  [[ "$output" == *"ok"*"third-party impeccable $(dep .skills.impeccable.version)"* ]]
  [[ "$output" == *"ok"*"IMPECCABLE_NO_STALENESS_CHECK"* ]]
  [ "$( cd "$HOME" && find . -printf '%p %y %s\n' | sort )" = "$before" ]
}

@test "doctor warns when the lock ref differs from the pin or is missing, with both values" {
  pinned_all; staleness_off
  lock grilling
  lock humanizer v2.11.1
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"third-party grilling"*"no ref"*"$(dep .skills.grilling.ref | cut -c1-12)"*"run sync"* ]]
  [[ "$output" == *"warn"*"third-party humanizer"*"v2.11.1"*"$(dep .skills.humanizer.ref)"* ]]
  [[ "$output" == *"ok"*"third-party handoff"* ]]
}

@test "doctor warns about a skill directory the lock does not know" {
  pinned_all; staleness_off
  unlock grilling
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"third-party grilling"*"lock"* ]]
}

@test "doctor warns when impeccable's version differs from the pin, with both versions" {
  pinned_all; staleness_off
  impeccable_at 4.2.0
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"third-party impeccable"*"4.2.0"*"$(dep .skills.impeccable.version)"* ]]
}

@test "doctor warns about impeccable agents that are still there" {
  pinned_all; staleness_off
  mkdir -p "$AGENTS"; echo x > "$AGENTS/impeccable-documenter.md"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"impeccable-documenter.md"*"run sync"* ]]
}

@test "doctor warns until IMPECCABLE_NO_STALENESS_CHECK=1 is set in the settings env or its own environment" {
  pinned_all
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"IMPECCABLE_NO_STALENESS_CHECK"* ]]
  IMPECCABLE_NO_STALENESS_CHECK=1 run "$CLI" doctor
  [[ "$output" == *"ok"*"IMPECCABLE_NO_STALENESS_CHECK"* ]]
  printf '{"env":{"IMPECCABLE_NO_STALENESS_CHECK":"0"}}\n' > "$CLAUDE_CONFIG_DIR/settings.json"
  run "$CLI" doctor
  [[ "$output" == *"warn"*"IMPECCABLE_NO_STALENESS_CHECK"* ]]
  staleness_off
  run "$CLI" doctor
  [[ "$output" == *"ok"*"IMPECCABLE_NO_STALENESS_CHECK"* ]]
}
