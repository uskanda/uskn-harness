#!/usr/bin/env bats
# Tests for bin/uskn-harness (spec: harness-sync, harness-doctor, user-layer-instructions, onboard-check).
# HOME and CLAUDE_CONFIG_DIR point into $BATS_TEST_TMPDIR; network steps are stubbed and logged.
# A fake `claude` in the temporary HOME's .local/bin sits first on PATH, so the real one never decides a result.

REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
CLI="$REPO/bin/uskn-harness"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export CLAUDE_CONFIG_DIR="$HOME/.claude"
  export USKN_HARNESS_DIR="$REPO"
  export USKN_HARNESS_STUB_NET=1
  export USKN_HARNESS_STUB_LOG="$BATS_TEST_TMPDIR/net.log"
  # The session state sync prunes lives under the fake HOME, never the real ~/.local/state.
  export XDG_STATE_HOME="$HOME/.local/state"; unset USKN_STATE_DIR
  mkdir -p "$HOME/.local/bin" "$CLAUDE_CONFIG_DIR/skills"
  : > "$USKN_HARNESS_STUB_LOG"
  SKILLS="$CLAUDE_CONFIG_DIR/skills"
  STABLE="$HOME/.local/share/uskn-harness"
  MIN="$(jq -r '.runtimes["claude-code"].min_version' "$REPO/deps.json")"
  export PATH="$HOME/.local/bin:$PATH"
  fake_claude "$MIN (Claude Code)"
}

fake_claude() { # <what `claude --version` prints>
  printf '#!/bin/sh\necho "%s"\n' "$1" > "$HOME/.local/bin/claude"
  chmod +x "$HOME/.local/bin/claude"
}
fake_extension() { # <extensions dir under HOME> <version> [platform]: a Claude Code VS Code extension directory
  mkdir -p "$HOME/$1/anthropic.claude-code-$2-${3:-linux-x64}"
}
# path_without_claude: PATH with every `claude` hidden. A directory that holds one is replaced by links to its
# other entries, so the tools living next to it (mise, node) still resolve.
path_without_claude() {
  local IFS=: dir f out="" shadow n=0
  for dir in $PATH; do
    if [ -e "$dir/claude" ]; then
      n=$((n + 1)); shadow="$BATS_TEST_TMPDIR/noclaude$n"; mkdir -p "$shadow"
      for f in "$dir"/*; do [ "${f##*/}" = claude ] || ln -s "$f" "$shadow/"; done
      dir="$shadow"
    fi
    out="${out:+$out:}$dir"
  done
  printf '%s' "$out"
}
claude_code_lines() { grep -E '^(ok|warn|fail) +Claude Code' <<<"$output" || true; }

# listing <format> [find tests...]: one sorted line per entry under the current directory, in find's printf notation
# (%p path, %y type, %s size, %T@ mtime, %l link target). Perl, because BSD find (macOS) has no printf action.
listing() {
  local fmt="$1"; shift
  find . "$@" | LC_ALL=C sort | FMT="$fmt" perl -MTime::HiRes=lstat -nle '
    my @s = lstat($_) or next;
    my %v = (p => $_, y => (-l _ ? "l" : -d _ ? "d" : -f _ ? "f" : "o"), s => $s[7], "T@" => $s[9], l => (-l _ ? readlink : ""));
    (my $line = $ENV{FMT}) =~ s/%(T@|[pysl])/$v{$1}/g; print $line'
}
snapshot() { ( cd "$HOME" && listing '%p %y %l' ); }
# age <days> <path>...: move the modification time of each path <days> days into the past
age() { local d="$1"; shift; perl -e 'my $t = time - shift(@ARGV) * 86400; utime($t, $t, @ARGV) == @ARGV or die "utime failed\n"' "$d" "$@"; }
# refute <command...>: fails when the command succeeds. A bare `! cmd` that is not the last line of a test never
# fails it (errexit ignores negated commands); the non-zero return of a function does.
refute() { ! "$@"; }
# dep <jq path>: a value from deps.json, so a pin bump needs no test edit.
dep() { jq -r "$1" "$REPO/deps.json"; }
# npm_specs <cli key>: the install arguments sync builds for a pinned npm cli -- package@version, then its bundle.
npm_specs() {
  jq -r --arg k "$1" '.clis[$k] | [ "\(.package)@\(.version)" ] + ((.bundle // {}) | to_entries | map("\(.key)@\(.value)")) | join(" ")' "$REPO/deps.json"
}

@test "snapshot lists every entry with its type and link target, so the writes-nothing tests compare something" {
  mkdir -p "$HOME/d"; echo x > "$HOME/d/f"; ln -s d/f "$HOME/l"
  run snapshot
  [[ "$output" == *"./d d"* ]] || false
  [[ "$output" == *"./d/f f"* ]] || false
  [[ "$output" == *"./l l d/f"* ]] || false
}

@test "--help prints usage and exits 0" {
  run "$CLI" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"sync"* ]] || false
  [[ "$output" == *"doctor"* ]] || false
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
  [[ "$output" == *"plan"* ]] || false
  [[ "$output" == *"$SKILLS/commit"* ]] || false
  [ ! -e "$STABLE" ]
}

@test "sync on a fresh machine links everything and records network steps" {
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ -L "$STABLE" ]
  [ "$(readlink -f "$STABLE")" = "$REPO" ]
  [ -L "$HOME/.local/bin/uskn-harness" ]
  [ "$(readlink -f "$HOME/.local/bin/uskn-harness")" = "$REPO/bin/uskn-harness" ]
  [ -L "$SKILLS/commit" ]
  [ "$(readlink -f "$SKILLS/commit")" = "$REPO/skills/git/commit" ]
  [ -L "$SKILLS/pr" ]
  [ -L "$SKILLS/mr-qa" ]
  [ -L "$SKILLS/uskn-harness" ]
  [ "$(readlink -f "$SKILLS/uskn-harness")" = "$REPO/plugins/uskn-harness" ]
  [ -L "$HOME/.local/share/openspec/schemas/uskn" ]
  [ "$(readlink -f "$HOME/.local/share/openspec/schemas/uskn")" = "$REPO/schemas/uskn" ]
  [ -f "$CLAUDE_CONFIG_DIR/CLAUDE.md" ]
  head -1 "$CLAUDE_CONFIG_DIR/CLAUDE.md" | grep -q "managed by uskn-harness"
  grep -qF "mise use -g node@$(dep .runtimes.node.version)" "$USKN_HARNESS_STUB_LOG"
  grep -qF "openspec@$(dep .clis.openspec.version)" "$USKN_HARNESS_STUB_LOG"
  grep -qF "skills@$(dep .clis.skills.version) add mattpocock/skills#$(dep .skills.grilling.ref)@grilling" "$USKN_HARNESS_STUB_LOG"
  [ ! -e "$HOME/.ai-sessions" ]
  [[ "$output" != *"sessions repo"* ]] || false
  [[ "$output" == *"created"* ]] || false
  run grep -q "git clone" "$USKN_HARNESS_STUB_LOG"; [ "$status" -ne 0 ]
}

@test "sync --tools installs the runtime, the pinned CLIs, and the schema link only; --tools --remove exits 2" {
  run "$CLI" sync --tools
  [ "$status" -eq 0 ]
  grep -qF "mise use -g node@$(dep .runtimes.node.version)" "$USKN_HARNESS_STUB_LOG"
  grep -qF "openspec@$(dep .clis.openspec.version)" "$USKN_HARNESS_STUB_LOG"
  [ -L "$HOME/.local/share/openspec/schemas/uskn" ]
  [ "$(readlink -f "$HOME/.local/share/openspec/schemas/uskn")" = "$REPO/schemas/uskn" ]
  [ ! -e "$STABLE" ]
  [ ! -e "$HOME/.local/bin/uskn-harness" ]
  [ ! -e "$SKILLS/commit" ]
  [ ! -e "$SKILLS/uskn-harness" ]
  [ ! -e "$CLAUDE_CONFIG_DIR/CLAUDE.md" ]
  [ ! -e "$HOME/.ai-sessions" ]
  refute grep -q "git clone" "$USKN_HARNESS_STUB_LOG"
  refute grep -q "skills@" "$USKN_HARNESS_STUB_LOG"
  refute grep -q "impeccable" "$USKN_HARNESS_STUB_LOG"
  refute grep -q "openspec-user-layer" "$USKN_HARNESS_STUB_LOG"
  run "$CLI" sync --tools; [ "$status" -eq 0 ]; [[ "$output" == *"ok"*"openspec schema uskn"* ]] || false
  run "$CLI" sync --tools --remove; [ "$status" -eq 2 ]
}

@test "second sync changes nothing and reports ok" {
  "$CLI" sync >/dev/null
  before="$(snapshot)"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ "$(snapshot)" = "$before" ]
  [[ "$output" != *"created"* ]] || false
  [[ "$output" == *"ok"* ]] || false
}

@test "existing real directory with a skill name is a conflict, left untouched, exit 0" {
  mkdir -p "$SKILLS/commit" && echo old > "$SKILLS/commit/SKILL.md"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"conflict"*"commit"* ]] || false
  [ ! -L "$SKILLS/commit" ]
  [ "$(cat "$SKILLS/commit/SKILL.md")" = old ]
  [ -L "$SKILLS/pr" ]
}

@test "symlink pointing outside the harness is a conflict" {
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere/pr" && ln -s "$BATS_TEST_TMPDIR/elsewhere/pr" "$SKILLS/pr"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"conflict"*"pr"* ]] || false
  [ "$(readlink "$SKILLS/pr")" = "$BATS_TEST_TMPDIR/elsewhere/pr" ]
}

@test "dangling or moved symlink into the harness is updated" {
  ln -s "$REPO/skills/old-location/pr" "$SKILLS/pr"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"updated"*"pr"* ]] || false
  [ "$(readlink -f "$SKILLS/pr")" = "$REPO/skills/git/pr" ]
}

@test "duplicate skill names abort before any write" {
  fx="$BATS_TEST_TMPDIR/fx"; mkdir -p "$fx/skills/a/dup" "$fx/skills/b/dup" "$fx/plugins/uskn-harness" "$fx/templates/user" "$fx/bin"
  printf -- '---\nname: dup\ndescription: x\n---\n' | tee "$fx/skills/a/dup/SKILL.md" > "$fx/skills/b/dup/SKILL.md"
  cp "$REPO/deps.json" "$fx/deps.json"; cp "$CLI" "$fx/bin/uskn-harness"; echo '<!-- managed by uskn-harness -->' > "$fx/templates/user/CLAUDE.md"
  before="$(snapshot)"
  USKN_HARNESS_DIR="$fx" run "$CLI" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"duplicate"* ]] || false
  [ "$(snapshot)" = "$before" ]
}

@test "the reserved skill name uskn-harness aborts with exit 2 before any write" {
  fx="$BATS_TEST_TMPDIR/fx"; mkdir -p "$fx/skills/a/uskn-harness" "$fx/skills/b/fine" "$fx/plugins/uskn-harness" "$fx/templates/user" "$fx/bin"
  printf -- '---\nname: uskn-harness\ndescription: x\n---\n' > "$fx/skills/a/uskn-harness/SKILL.md"
  printf -- '---\nname: fine\ndescription: x\n---\n' > "$fx/skills/b/fine/SKILL.md"
  cp "$REPO/deps.json" "$fx/deps.json"; cp "$CLI" "$fx/bin/uskn-harness"; echo '<!-- managed by uskn-harness -->' > "$fx/templates/user/CLAUDE.md"
  before="$(snapshot)"
  USKN_HARNESS_DIR="$fx" run "$CLI" sync
  [ "$status" -eq 2 ]
  [[ "$output" == *"reserved"* ]] || false
  [ "$(snapshot)" = "$before" ]
}

@test "a failed step: sync finishes the other steps, reports on stderr, and exits 1" {
  USKN_HARNESS_STUB_FAIL='npm global textlint' run "$CLI" sync
  [ "$status" -eq 1 ]
  [[ "$output" == *"fail"*"npm global textlint"* ]] || false
  [[ "$output" == *"run 'uskn-harness sync' again"* ]] || false
  [ -L "$SKILLS/commit" ]
  [ -f "$CLAUDE_CONFIG_DIR/CLAUDE.md" ]
  run "$CLI" sync
  [ "$status" -eq 0 ]
}

@test "sync --tools exits 1 when a pinned CLI fails to install" {
  USKN_HARNESS_STUB_FAIL='npm global *' run "$CLI" sync --tools
  [ "$status" -eq 1 ]
  [[ "$output" == *"fail"*"npm global"* ]] || false
}

@test "a failed checkout update is a warning: sync still exits 0" {
  make_checkout; advance_origin one
  USKN_HARNESS_DIR="$WORK" USKN_HARNESS_STUB_FAIL='harness pull*' run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"harness pull"* ]] || false
}

@test "a hand-written ~/.claude/CLAUDE.md is preserved and reported as conflict" {
  echo "# mine" > "$CLAUDE_CONFIG_DIR/CLAUDE.md"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"conflict"*"CLAUDE.md"* ]] || false
  [ "$(cat "$CLAUDE_CONFIG_DIR/CLAUDE.md")" = "# mine" ]
}

@test "a managed ~/.claude/CLAUDE.md is refreshed when the template changes" {
  "$CLI" sync >/dev/null
  echo "stale" >> "$CLAUDE_CONFIG_DIR/CLAUDE.md"
  run "$CLI" sync
  [[ "$output" == *"updated"*"CLAUDE.md"* ]] || false
  cmp -s "$CLAUDE_CONFIG_DIR/CLAUDE.md" "$REPO/templates/user/CLAUDE.md"
}

@test "third-party skill already present is not reinstalled" {
  mkdir -p "$SKILLS/grilling" && touch "$SKILLS/grilling/SKILL.md"
  run "$CLI" sync
  refute grep -q "grilling" "$USKN_HARNESS_STUB_LOG"
}

@test "sync --remove deletes harness symlinks only" {
  "$CLI" sync >/dev/null
  mkdir -p "$SKILLS/keepme" && echo "# mine" > "$SKILLS/keepme/SKILL.md"
  run "$CLI" sync --remove
  [ "$status" -eq 0 ]
  [ ! -e "$SKILLS/commit" ]
  [ ! -e "$SKILLS/uskn-harness" ]
  [ ! -e "$HOME/.local/bin/uskn-harness" ]
  [ ! -e "$STABLE" ]
  [ ! -e "$HOME/.local/share/openspec/schemas/uskn" ]
  [ -d "$SKILLS/keepme" ]
  [ ! -e "$CLAUDE_CONFIG_DIR/CLAUDE.md" ]
}

@test "an existing ~/.ai-sessions is left untouched and never mentioned by sync or doctor" {
  mkdir -p "$HOME/.ai-sessions/.git" "$HOME/.ai-sessions/o__r"
  echo journal > "$HOME/.ai-sessions/o__r/2026-09-01-0900-abcdef12.md"
  before="$( cd "$HOME/.ai-sessions" && listing '%p %y %s %T@' )"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" != *"ai-sessions"* ]] || false
  [[ "$output" != *"sessions repo"* ]] || false
  refute grep -q "ai-sessions" "$USKN_HARNESS_STUB_LOG"
  run "$CLI" doctor
  [[ "$output" != *"ai-sessions"* ]] || false
  [[ "$output" != *"sessions repo"* ]] || false
  [ "$( cd "$HOME/.ai-sessions" && listing '%p %y %s %T@' )" = "$before" ]
}

@test "doctor does not ask for a sessions repo when ~/.ai-sessions is missing" {
  "$CLI" sync >/dev/null
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" != *"sessions repo"* ]] || false
  [ ! -e "$HOME/.ai-sessions" ]
}

@test "sync removes session state untouched for 30 days and keeps the rest; --dry-run and --tools remove nothing" {
  st="$HOME/.local/state/uskn-harness/sessions"
  mkdir -p "$st/old" "$st/recent" "$st/old-dir-new-file"
  echo x > "$st/old/baseline"; echo x > "$st/recent/baseline"; echo x > "$st/old-dir-new-file/verify.log"
  age 40 "$st/old/baseline" "$st/old" "$st/old-dir-new-file"
  age 1 "$st/recent/baseline" "$st/recent" "$st/old-dir-new-file/verify.log"
  run "$CLI" sync --dry-run
  [ "$status" -eq 0 ]
  [ -d "$st/old" ]
  [[ "$output" == *"plan"*"$st/old"* ]] || false
  [[ "$output" != *"$st/old-dir-new-file"* ]] || false
  [[ "$output" != *"$st/recent"* ]] || false
  run "$CLI" sync --tools
  [ "$status" -eq 0 ]
  [ -d "$st/old" ]
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ ! -e "$st/old" ]
  [ -d "$st/recent" ]
  [ -d "$st/old-dir-new-file" ]
  [[ "$output" == *"removed"*"session state"* ]] || false
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" != *"removed"* ]] || false
}

@test "session state pruning follows USKN_STATE_DIR and touches nothing outside sessions/" {
  export USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"
  mkdir -p "$USKN_STATE_DIR/sessions/old" "$USKN_STATE_DIR/other"
  age 40 "$USKN_STATE_DIR/sessions/old" "$USKN_STATE_DIR/other"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ ! -e "$USKN_STATE_DIR/sessions/old" ]
  [ -d "$USKN_STATE_DIR/other" ]
}

@test "sync removes a skill symlink whose target inside the harness is gone; a dangling link elsewhere stays" {
  ln -s "$REPO/skills/retired-skill" "$SKILLS/retired-skill"
  ln -s "$BATS_TEST_TMPDIR/nowhere/mine" "$SKILLS/mine"
  run "$CLI" sync --dry-run
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/retired-skill" ]
  [[ "$output" == *"plan"*"$SKILLS/retired-skill"* ]] || false
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ ! -L "$SKILLS/retired-skill" ]
  [[ "$output" == *"removed"*"retired-skill"* ]] || false
  [ -L "$SKILLS/mine" ]
  [[ "$output" != *"retired skill link mine "* ]] || false
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
  [[ "$output" == *"fail"*"pr"* ]] || false
}

@test "doctor: real-directory conflict alone is warn, exit 0" {
  mkdir -p "$SKILLS/commit" && echo old > "$SKILLS/commit/SKILL.md"
  "$CLI" sync >/dev/null
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"commit"* ]] || false
}

@test "doctor before sync reports missing items as warn and the stable path as warn" {
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"* ]] || false
}

@test "templates/repo carries no CLAUDE.md, and its AGENTS.md offers an optional Claude Code section" {
  [ ! -e "$REPO/templates/repo/CLAUDE.md" ]
  grep -q '^## Claude Code' "$REPO/templates/repo/AGENTS.md"
}

@test "templates/user/CLAUDE.md is under 60 lines and 2,000 bytes and starts with the marker" {
  [ "$(wc -l < "$REPO/templates/user/CLAUDE.md")" -le 60 ]
  [ "$(wc -c < "$REPO/templates/user/CLAUDE.md")" -le 2000 ]
  head -1 "$REPO/templates/user/CLAUDE.md" | grep -q "managed by uskn-harness"
}

@test "templates/user/CLAUDE.md names no skill the harness has retired" {
  for s in verification-before-completion using-git-worktrees pre-merge nessun-dorma; do
    refute grep -q -- "$s" "$REPO/templates/user/CLAUDE.md"
  done
}

# ---- Claude Code minimum version (spec: harness-doctor, harness-sync)

@test "doctor: an old claude CLI is warn with both versions and says AGENTS.md is not read" {
  fake_claude "2.1.270 (Claude Code)"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  line="$(claude_code_lines)"
  [ "$(grep -c . <<<"$line")" -eq 1 ]
  [[ "$line" == "warn"*"$HOME/.local/bin/claude"* ]] || false
  [[ "$line" == *"2.1.270"* ]] || false
  [[ "$line" == *"$MIN"* ]] || false
  [[ "$line" == *"AGENTS.md"* ]] || false
  [[ "$line" == *"CLAUDE.md"* ]] || false
}

@test "doctor: a claude CLI at or above the minimum is ok, however new" {
  for v in 2.1.282 3.0.0; do
    fake_claude "$v (Claude Code)"
    run "$CLI" doctor
    line="$(claude_code_lines)"
    [[ "$line" == "ok"*"$HOME/.local/bin/claude"*"$v"* ]] || false
    refute grep -q '^warn' <<<"$line"
  done
}

@test "doctor: a claude CLI whose version cannot be read is warn with the output attached" {
  fake_claude "unknown option --version"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  line="$(claude_code_lines)"
  [[ "$line" == "warn"*"$HOME/.local/bin/claude"* ]] || false
  [[ "$line" == *"unknown option --version"* ]] || false
}

@test "doctor: an old VS Code extension is warn with its directory and both versions" {
  fake_extension .vscode-server/extensions 2.1.279
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  line="$(claude_code_lines | grep vscode)"
  [[ "$line" == "warn"*"$HOME/.vscode-server/extensions/anthropic.claude-code-2.1.279-linux-x64"* ]] || false
  [[ "$line" == *"$MIN"* ]] || false
  [[ "$line" == *"AGENTS.md"* ]] || false
}

@test "doctor: ~/.vscode/extensions is checked as well" {
  fake_extension .vscode/extensions 2.1.279 darwin-arm64
  run "$CLI" doctor
  line="$(claude_code_lines | grep vscode)"
  [[ "$line" == "warn"*"$HOME/.vscode/extensions/anthropic.claude-code-2.1.279-darwin-arm64"* ]] || false
}

@test "doctor: only the newest extension in one extensions directory is compared" {
  fake_extension .vscode-server/extensions 2.1.279
  fake_extension .vscode-server/extensions 2.1.282
  run "$CLI" doctor
  line="$(claude_code_lines | grep vscode)"
  [ "$(grep -c . <<<"$line")" -eq 1 ]
  [[ "$line" == "ok"*"anthropic.claude-code-2.1.282-linux-x64"* ]] || false
  refute grep -q '2\.1\.279' <<<"$output"
}

@test "doctor: an old CLI next to a new extension gives exactly one warn" {
  fake_claude "2.1.270 (Claude Code)"
  fake_extension .vscode-server/extensions 2.1.282
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [ "$(claude_code_lines | grep -c '^warn')" -eq 1 ]
  [[ "$(claude_code_lines | grep '^warn')" == *"$HOME/.local/bin/claude"* ]] || false
  [[ "$(claude_code_lines | grep vscode)" == "ok"* ]] || false
}

@test "doctor: no Claude Code line when there is neither a claude on PATH nor a VS Code extension" {
  run "$CLI" doctor
  [[ "$(claude_code_lines)" == "ok"* ]] || false   # control: the default fake claude is reported
  rm "$HOME/.local/bin/claude"
  export PATH="$(path_without_claude)"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  refute grep -q 'Claude Code' <<<"$output"
}

@test "sync never installs or pins Claude Code; deps.json keeps only a floor for it" {
  jq -e '.runtimes["claude-code"] | has("min_version") and (has("version") | not)' "$REPO/deps.json"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  refute grep -qE '@anthropic-ai/claude-code|claude\.ai/install|claude update' "$USKN_HARNESS_STUB_LOG"
}

# ---- phase 3: pinned npm CLIs (textlint, agent-style, design.md) and UI skills (spec: harness-sync, harness-doctor)

@test "sync installs the pinned npm CLIs with their bundles and the UI / writing skills from deps.json" {
  run "$CLI" sync
  [ "$status" -eq 0 ]
  for cli in textlint agent-style designmd; do grep -qF "npm install -g $(npm_specs "$cli")" "$USKN_HARNESS_STUB_LOG"; done
  grep -qF "releases/download/$(dep .skills.impeccable.ref)/" "$USKN_HARNESS_STUB_LOG"
  grep -qF "anthropics/claude-plugins-official#$(dep '.skills["frontend-design"].ref')@frontend-design" "$USKN_HARNESS_STUB_LOG"
  for s in ja-writing en-writing ui-guidelines test-driven-development systematic-debugging verify; do
    [ -L "$SKILLS/$s" ]
    [ "$(readlink -f "$SKILLS/$s")" = "$REPO/skills/$s" ]
  done
}

@test "sync skips an npm CLI whose package and bundle are already at the pinned versions" {
  export USKN_NPM_ROOT="$BATS_TEST_TMPDIR/npm"
  for p in $(npm_specs textlint) $(npm_specs agent-style); do   # scoped names start with @: split at the last one
    mkdir -p "$USKN_NPM_ROOT/${p%@*}"; printf '{"version":"%s"}\n' "${p##*@}" > "$USKN_NPM_ROOT/${p%@*}/package.json"
  done
  run "$CLI" sync
  [ "$status" -eq 0 ]
  refute grep -qF "textlint@$(dep .clis.textlint.version)" "$USKN_HARNESS_STUB_LOG"
  refute grep -qF "agent-style@$(dep '.clis["agent-style"].version')" "$USKN_HARNESS_STUB_LOG"
  grep -qF "@google/design.md@$(dep .clis.designmd.version)" "$USKN_HARNESS_STUB_LOG"
  [[ "$output" == *"ok"*"textlint $(dep .clis.textlint.version)"* ]] || false
}

@test "doctor warns about a missing or mismatched npm CLI and reports the pinned version" {
  export USKN_NPM_ROOT="$BATS_TEST_TMPDIR/npm"
  mkdir -p "$USKN_NPM_ROOT/textlint"; echo '{"version":"15.0.0"}' > "$USKN_NPM_ROOT/textlint/package.json"
  run "$CLI" doctor
  [ "$(dep .clis.textlint.version)" != 15.0.0 ]
  [[ "$output" == *"warn"*"textlint"*"15.0.0"*"$(dep .clis.textlint.version)"* ]] || false
  [[ "$output" == *"warn"*"agent-style"*"none"* ]] || false
  [[ "$output" == *"warn"*"third-party impeccable"* ]] || false
}

# ---- mise global node: another node on PATH (Homebrew) and a caller's mise.toml decide nothing (spec: harness-sync)

# fake_mise [global node version]: a mise that logs "<cwd> <args>" to $MISE_LOG and runs nothing real. `current node`
# prints the version only in /, where a project's mise.toml cannot apply. A node 24 that is not mise's sits on PATH
# next to it, as Homebrew's does. The tests that use it run without the stub, so USKN_NPM_ROOT keeps npm root fake.
fake_mise() {
  export USKN_HARNESS_STUB_NET=0 MISE_LOG="$BATS_TEST_TMPDIR/mise.log" USKN_NPM_ROOT="$BATS_TEST_TMPDIR/npm"
  mkdir -p "$USKN_NPM_ROOT"; : > "$MISE_LOG"
  cat > "$HOME/.local/bin/mise" <<EOF
#!/bin/sh
if [ "\$1" = -C ]; then cd "\$2" || exit 1; shift 2; fi
printf '%s %s\n' "\$PWD" "\$*" >> "$MISE_LOG"
case "\$1" in
  current) [ "\$PWD" = / ] && [ -n "${1:-}" ] && echo "${1:-}"; exit 0 ;;
  exec) shift; [ "\$1" = -- ] && shift; [ "\$1" = npm ] && exit 0; exec "\$@" ;;
esac
EOF
  printf '#!/bin/sh\necho v24.9.0\n' > "$HOME/.local/bin/node"
  chmod +x "$HOME/.local/bin/mise" "$HOME/.local/bin/node"
  mkdir -p "$BATS_TEST_TMPDIR/project"; printf '[tools]\nnode = "24"\n' > "$BATS_TEST_TMPDIR/project/mise.toml"
}

@test "sync sets the mise global node when the node 24 on PATH is not mise's" {
  fake_mise
  cd "$BATS_TEST_TMPDIR/project"
  run "$CLI" sync --tools
  [ "$status" -eq 0 ]
  grep -qF "use -g node@$(dep .runtimes.node.version)" "$MISE_LOG"
  [[ "$output" == *"created"*"node $(dep .runtimes.node.version) (mise global)"* ]] || false
}

@test "sync keeps a mise global node at the pinned major" {
  fake_mise "$(dep .runtimes.node.version).21.0"
  run "$CLI" sync --tools
  [ "$status" -eq 0 ]
  refute grep -qF "use -g node@" "$MISE_LOG"
  [[ "$output" == *"ok"*"node $(dep .runtimes.node.version).21.0 (mise global)"* ]] || false
}

@test "sync installs the pinned npm CLIs from /, not under the caller's mise.toml" {
  fake_mise "$(dep .runtimes.node.version).21.0"
  cd "$BATS_TEST_TMPDIR/project"
  run "$CLI" sync --tools
  [ "$status" -eq 0 ]
  grep -qF "/ exec -- npm install -g $(npm_specs textlint)" "$MISE_LOG"
  refute grep -qF "$BATS_TEST_TMPDIR/project exec -- npm install -g" "$MISE_LOG"
}

@test "doctor warns when mise has no global node, even with a node 24 on PATH" {
  fake_mise
  run "$CLI" doctor
  [[ "$output" == *"warn"*"no mise global node"*"run sync"* ]] || false
}

@test "doctor reports the mise global node at the pinned major as ok" {
  fake_mise "$(dep .runtimes.node.version).21.0"
  run "$CLI" doctor
  [[ "$output" == *"ok"*"node $(dep .runtimes.node.version).21.0 (mise global)"* ]] || false
}

# ---- phase 4: onboard-check (spec: onboard-check)

fixture_repo() { # <dir> [ui]  -- a bare product repo, optionally with a UI dependency
  mkdir -p "$1"; ( cd "$1" && git init -q -b main )
  [ "${2:-}" = ui ] && printf '{"dependencies":{"expo":"~54.0.0","react":"19.1.0"}}\n' > "$1/package.json"
  return 0
}
onboarded_repo() { # <dir> -- everything onboard-harness would place, with a UI dependency (no CLAUDE.md)
  fixture_repo "$1" ui
  printf '# product\n' > "$1/AGENTS.md"
  mkdir -p "$1/openspec/specs" "$1/openspec/changes"; printf 'schema: uskn\n' > "$1/openspec/config.yaml"
  printf 'verify:\n\t@echo ok\n' > "$1/Makefile"
  printf '%s\n' '---' 'name: x' '---' > "$1/DESIGN.md"; printf '# Product\n' > "$1/PRODUCT.md"
}

@test "onboard-check on an untouched repo warns about every item but CLAUDE.md and still exits 0" {
  P="$BATS_TEST_TMPDIR/fresh"; fixture_repo "$P" ui
  run "$CLI" onboard-check "$P"
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"AGENTS.md"* ]] || false
  [[ "$output" == *"warn"*"openspec"* ]] || false
  [[ "$output" == *"warn"*"verify"* ]] || false
  [[ "$output" == *"warn"*"DESIGN.md"* ]] || false
  [[ "$output" == *"warn"*"PRODUCT.md"* ]] || false
  refute grep -q '^warn .*CLAUDE' <<<"$output"
  [ "$(grep -c '^ok ' <<<"$output")" -eq 1 ]
  grep -q '^ok .*CLAUDE.md' <<<"$output"
}

@test "onboard-check on an onboarded repo reports ok for every item" {
  P="$BATS_TEST_TMPDIR/done"; onboarded_repo "$P"
  run "$CLI" onboard-check "$P"
  [ "$status" -eq 0 ]
  [[ "$output" != *"warn"* ]] || false
  [[ "$output" == *"ok"*"AGENTS.md"* ]] || false
  grep -q '^ok .*CLAUDE.md' <<<"$output"
  [[ "$output" == *"ok"*"schema: uskn"* ]] || false
  [[ "$output" == *"ok"*"make verify"* ]] || false
}

@test "onboard-check writes nothing into the target repository" {
  P="$BATS_TEST_TMPDIR/ro"; onboarded_repo "$P"
  before="$( cd "$P" && listing '%p %s' -not -path './.git/*' )"
  run "$CLI" onboard-check "$P"
  [ "$status" -eq 0 ]
  [ "$( cd "$P" && listing '%p %s' -not -path './.git/*' )" = "$before" ]
}

@test "onboard-check skips DESIGN.md and PRODUCT.md when the repo has no UI dependency" {
  P="$BATS_TEST_TMPDIR/noui"; fixture_repo "$P"
  run "$CLI" onboard-check "$P"
  [ "$status" -eq 0 ]
  [[ "$output" != *"DESIGN.md"* ]] || false
  [[ "$output" != *"PRODUCT.md"* ]] || false
  [[ "$output" == *"AGENTS.md"* ]] || false
}

@test "onboard-check warns when a project skill shadows a user-layer skill" {
  P="$BATS_TEST_TMPDIR/dup"; onboarded_repo "$P"
  mkdir -p "$P/.claude/skills/commit" "$P/.claude/skills/release-expo" "$SKILLS/commit"
  run "$CLI" onboard-check "$P"
  [ "$status" -eq 0 ]
  [[ "$output" == *"commit"* ]] || false
  [[ "$output" == *"warn"* ]] || false
  [[ "$output" != *"warn"*"release-expo"* ]] || false
}

@test "onboard-check: a CLAUDE.md that imports @AGENTS.md is ok" {
  P="$BATS_TEST_TMPDIR/import"; onboarded_repo "$P"
  printf '@AGENTS.md\n' > "$P/CLAUDE.md"
  run "$CLI" onboard-check "$P"
  [[ "$output" != *"warn"* ]] || false
  grep -q '^ok .*CLAUDE.md -> @AGENTS.md' <<<"$output"
}

@test "onboard-check warns when CLAUDE.md does not import AGENTS.md, and says AGENTS.md goes unread" {
  P="$BATS_TEST_TMPDIR/stale"; onboarded_repo "$P"
  printf '# rules\n\n色々書いてある\n' > "$P/CLAUDE.md"
  run "$CLI" onboard-check "$P"
  line="$(grep '^warn .*CLAUDE.md' <<<"$output")"
  [[ "$line" == *"AGENTS.md"*"not read"* ]] || false
  refute grep -q '^ok .*CLAUDE' <<<"$output"
}

@test "onboard-check judges .claude/CLAUDE.md the same way" {
  P="$BATS_TEST_TMPDIR/dotclaude"; onboarded_repo "$P"
  mkdir -p "$P/.claude"; printf '# rules\n' > "$P/.claude/CLAUDE.md"
  run "$CLI" onboard-check "$P"
  grep -q '^warn .*\.claude/CLAUDE.md' <<<"$output"
  printf '@AGENTS.md\n' > "$P/.claude/CLAUDE.md"
  run "$CLI" onboard-check "$P"
  [[ "$output" != *"warn"* ]] || false
  grep -q '^ok .*\.claude/CLAUDE.md -> @AGENTS.md' <<<"$output"
}

@test "onboard-check warns about CLAUDE.local.md in a repo that relies on AGENTS.md, and names the fix" {
  P="$BATS_TEST_TMPDIR/local"; onboarded_repo "$P"
  printf '# mine\n' > "$P/CLAUDE.local.md"
  run "$CLI" onboard-check "$P"
  [ "$status" -eq 0 ]
  line="$(grep '^warn .*CLAUDE.local.md' <<<"$output")"
  [[ "$line" == *"AGENTS.md"* ]] || false
  [[ "$line" == *"delete"* ]] || false
  [[ "$line" == *"claude-md-and-agents-md"* ]] || false
  refute grep -q '^ok .*CLAUDE' <<<"$output"
}

@test "onboard-check: CLAUDE.local.md is fine next to a CLAUDE.md that imports @AGENTS.md" {
  P="$BATS_TEST_TMPDIR/local-ok"; onboarded_repo "$P"
  printf '@AGENTS.md\n' > "$P/CLAUDE.md"; printf '# mine\n' > "$P/CLAUDE.local.md"
  run "$CLI" onboard-check "$P"
  [[ "$output" != *"warn"* ]] || false
  grep -q '^ok .*CLAUDE.md -> @AGENTS.md' <<<"$output"
}

@test "onboard-check defaults to the current directory and reports the path" {
  P="$BATS_TEST_TMPDIR/cwd"; onboarded_repo "$P"
  run bash -c "cd '$P' && '$CLI' onboard-check"
  [ "$status" -eq 0 ]
  [[ "$output" == *"$P"* ]] || false
}

# ---------------------------------------------------------------- checkout update (spec: harness-sync)
# A throwaway bare origin plus a clone that looks like a harness checkout, so the pull never touches this repo.
make_checkout() {
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  ORIGIN="$BATS_TEST_TMPDIR/origin.git"; SEED="$BATS_TEST_TMPDIR/seed"; WORK="$BATS_TEST_TMPDIR/work"
  git init -q --bare "$ORIGIN"; git --git-dir="$ORIGIN" symbolic-ref HEAD refs/heads/main
  git init -q "$SEED"; ( cd "$SEED" && git checkout -q -b main )
  cp "$REPO/deps.json" "$SEED/deps.json"
  ( cd "$SEED" && git add -A && git commit -qm init && git remote add origin "$ORIGIN" && git push -q -u origin main )
  git clone -q "$ORIGIN" "$WORK"
}
advance_origin() { ( cd "$SEED" && echo "$1" > marker.txt && git add -A && git commit -qm "$1" && git push -q origin main ); }
head_of() { git -C "$WORK" rev-parse HEAD; }
# update_checkout with the script sourced: the pull runs for real against the local origin.
update() { run env USKN_HARNESS_STUB_NET=0 bash -c "USKN_HARNESS_SOURCED=1 . '$CLI'; HARNESS='$WORK'; update_checkout"; }

@test "update: a clean checkout behind its upstream is fast-forwarded and reported" {
  make_checkout; before="$(head_of)"; advance_origin one
  update
  [ "$status" -eq 0 ]; [[ "$output" == *"updated"* ]] || false
  [ "$(head_of)" != "$before" ]; [ -f "$WORK/marker.txt" ]
}

@test "update: already current says so and pulls nothing new" {
  make_checkout; before="$(head_of)"
  update
  [ "$status" -eq 0 ]; [[ "$output" == *"up to date"* ]] || false; [ "$(head_of)" = "$before" ]
}

@test "update: uncommitted changes, detached HEAD, and a branch without upstream all skip" {
  make_checkout; advance_origin one; before="$(head_of)"
  echo dirt >> "$WORK/deps.json"
  update; [[ "$output" == *"uncommitted"* ]] || false; [ "$(head_of)" = "$before" ]
  git -C "$WORK" checkout -q -- deps.json
  git -C "$WORK" checkout -q --detach
  update; [[ "$output" == *"detached"* ]] || false; [ "$(head_of)" = "$before" ]
  git -C "$WORK" checkout -q main && git -C "$WORK" checkout -q -b local-only
  update; [[ "$output" == *"upstream"* ]] || false; [ "$(head_of)" = "$before" ]
}

@test "update: a diverged checkout is never merged; it reports the failure and returns 0" {
  make_checkout; advance_origin one
  ( cd "$WORK" && echo x > local.txt && git add -A && git commit -qm local )
  before="$(head_of)"
  update
  [ "$status" -eq 0 ]; [ "$(head_of)" = "$before" ]; [[ "$output" == *"fail"* ]] || false
}

@test "update: USKN_HARNESS_REEXEC=1 does nothing, so the re-exec cannot loop" {
  make_checkout; advance_origin one; before="$(head_of)"
  run env USKN_HARNESS_STUB_NET=0 USKN_HARNESS_REEXEC=1 bash -c "USKN_HARNESS_SOURCED=1 . '$CLI'; HARNESS='$WORK'; update_checkout"
  [ "$status" -eq 0 ]; [ -z "$output" ]; [ "$(head_of)" = "$before" ]
}

@test "sync updates the checkout first; --tools, --remove, --no-pull and --dry-run do not" {
  make_checkout; advance_origin one
  USKN_HARNESS_DIR="$WORK" run "$CLI" sync
  [ "$status" -eq 0 ]; grep -q "pull --ff-only" "$USKN_HARNESS_STUB_LOG"
  for opt in --tools --remove --no-pull; do
    : > "$USKN_HARNESS_STUB_LOG"
    USKN_HARNESS_DIR="$WORK" run "$CLI" sync "$opt"
    [ "$status" -eq 0 ]
    refute grep -q "pull --ff-only" "$USKN_HARNESS_STUB_LOG"
  done
  : > "$USKN_HARNESS_STUB_LOG"
  USKN_HARNESS_DIR="$WORK" run "$CLI" sync --dry-run
  [ "$status" -eq 0 ]; [[ "$output" == *"plan"* ]] || false; [[ "$output" == *"pull --ff-only"* ]] || false
  refute grep -q "pull --ff-only" "$USKN_HARNESS_STUB_LOG"
}

# ---------------------------------------------------------------- OpenSpec user layer (spec: harness-sync, harness-doctor)
# A mise that runs its command and an openspec that records the config it saw, then writes what delivery asks for.
fake_openspec() {
  FAKE="$BATS_TEST_TMPDIR/fakebin"; mkdir -p "$FAKE"
  export OPENSPEC_LOG="$BATS_TEST_TMPDIR/openspec" XDG_CONFIG_HOME="$HOME/.config"
  cat > "$FAKE/mise" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "${XDG_CONFIG_HOME:-}" > "$OPENSPEC_LOG.mise-xdg"
[ "${1:-}" = exec ] && shift; [ "${1:-}" = -- ] && shift
exec "$@"
SH
  cat > "$FAKE/openspec" <<'SH'
#!/usr/bin/env bash
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/openspec/config.json"
printf '%s\n' "${XDG_CONFIG_HOME:-}" > "$OPENSPEC_LOG.xdg"
cat "$cfg" > "$OPENSPEC_LOG.cfg" 2>/dev/null
delivery=both
grep -q '"delivery"[[:space:]]*:[[:space:]]*"commands"' "$cfg" 2>/dev/null && delivery=commands
mkdir -p .claude/commands/opsx
for w in apply archive explore propose sync update; do echo "$w" > ".claude/commands/opsx/$w.md"; done
if [ "$delivery" = both ]; then mkdir -p .claude/skills/openspec-propose && echo x > .claude/skills/openspec-propose/SKILL.md; fi
SH
  chmod +x "$FAKE/mise" "$FAKE/openspec"
  export PATH="$FAKE:$PATH"
  mkdir -p "$XDG_CONFIG_HOME/openspec"
  printf '{"telemetry":{"noticeSeen":true}}\n' > "$XDG_CONFIG_HOME/openspec/config.json"
  cp "$XDG_CONFIG_HOME/openspec/config.json" "$BATS_TEST_TMPDIR/user-config.orig"
}
# ensure_openspec_user_layer with the script sourced and the stub off: it runs the fake mise and openspec.
user_layer() { run env USKN_HARNESS_STUB_NET=0 bash -c "USKN_HARNESS_SOURCED=1 . '$CLI'; HARNESS='$REPO'; ensure_openspec_user_layer"; }
opsx_commands() { # <dir>: the six core workflow commands with the marker
  mkdir -p "$1"; : > "$1/.uskn-harness-managed"
  for w in apply archive explore propose sync update; do echo x > "$1/$w.md"; done
}

@test "openspec user layer: generated with a temporary config (core, commands); the user's config is untouched" {
  fake_openspec
  user_layer
  [ "$status" -eq 0 ]
  seen="$(cat "$OPENSPEC_LOG.xdg")"
  [ -n "$seen" ]
  [ "$seen" != "$XDG_CONFIG_HOME" ]
  [ ! -e "$seen" ]
  grep -q '"delivery":"commands"' "$OPENSPEC_LOG.cfg"
  grep -q '"profile":"core"' "$OPENSPEC_LOG.cfg"
  [ "$(cat "$OPENSPEC_LOG.mise-xdg")" = "$XDG_CONFIG_HOME" ]
  cmp -s "$XDG_CONFIG_HOME/openspec/config.json" "$BATS_TEST_TMPDIR/user-config.orig"
}

@test "openspec user layer: only commands/opsx is installed, with the marker; no openspec-* skill" {
  fake_openspec
  user_layer
  [ "$status" -eq 0 ]
  [[ "$output" == *"created"*"openspec commands opsx"* ]] || false
  [ -f "$CLAUDE_CONFIG_DIR/commands/opsx/.uskn-harness-managed" ]
  [ "$(ls "$CLAUDE_CONFIG_DIR/commands/opsx"/*.md | wc -l)" -eq 6 ]
  refute compgen -G "$SKILLS/openspec-*"
}

@test "sync removes the openspec-* skills an earlier sync installed, keeps unmarked ones, and only plans under --dry-run" {
  mkdir -p "$SKILLS/openspec-propose" "$SKILLS/openspec-explore"
  : > "$SKILLS/openspec-propose/.uskn-harness-managed"; echo x > "$SKILLS/openspec-propose/SKILL.md"
  echo mine > "$SKILLS/openspec-explore/SKILL.md"
  run "$CLI" sync --dry-run
  [ "$status" -eq 0 ]
  [ -d "$SKILLS/openspec-propose" ]
  [[ "$output" == *"plan"*"remove $SKILLS/openspec-propose"* ]] || false
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ ! -e "$SKILLS/openspec-propose" ]
  [[ "$output" == *"removed"*"openspec-propose"* ]] || false
  [ "$(cat "$SKILLS/openspec-explore/SKILL.md")" = mine ]
}

@test "doctor: the six openspec commands are ok; openspec-* skills are no longer checked" {
  "$CLI" sync >/dev/null
  opsx_commands "$CLAUDE_CONFIG_DIR/commands/opsx"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"*"openspec commands opsx"* ]] || false
  [[ "$output" != *"openspec skill"* ]] || false
}

@test "doctor: a missing openspec command, a missing marker, or no commands at all is warn with the name" {
  "$CLI" sync >/dev/null
  O="$CLAUDE_CONFIG_DIR/commands/opsx"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"openspec commands opsx"*"missing"*"sync"* ]] || false
  opsx_commands "$O"; rm "$O/archive.md"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"openspec commands opsx"*"archive"*"sync"* ]] || false
  echo x > "$O/archive.md"; rm "$O/.uskn-harness-managed"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"openspec commands opsx"*"not harness-managed"* ]] || false
}

# ---------------------------------------------------------------- stale skill links (spec: harness-sync, harness-doctor)

@test "sync removes symlinks into the harness skills/ whose target is gone, and nothing else" {
  "$CLI" sync >/dev/null
  mkdir -p "$SKILLS/real"
  ln -s "$REPO/skills/git/retired-skill" "$SKILLS/retired-skill"
  ln -s "$STABLE/skills/retired-too" "$SKILLS/retired-too"
  ln -s "$BATS_TEST_TMPDIR/elsewhere/gone" "$SKILLS/mine"
  rm "$SKILLS/pr"; ln -s "$REPO/skills/old-location/pr" "$SKILLS/pr"
  run "$CLI" sync --dry-run
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/retired-skill" ]
  [[ "$output" == *"plan"*"remove $SKILLS/retired-skill"* ]] || false
  [[ "$output" != *"remove $SKILLS/pr"* ]] || false
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ ! -L "$SKILLS/retired-skill" ]
  [ ! -L "$SKILLS/retired-too" ]
  [[ "$output" == *"removed"*"retired-skill"* ]] || false
  [ -L "$SKILLS/mine" ]
  [ -d "$SKILLS/real" ]
  [[ "$output" == *"updated"*"pr"* ]] || false
  [ "$(readlink -f "$SKILLS/pr")" = "$REPO/skills/git/pr" ]
}

@test "sync --remove also removes a dangling symlink into the harness skills/" {
  "$CLI" sync >/dev/null
  ln -s "$REPO/skills/git/retired-skill" "$SKILLS/retired-skill"
  ln -s "$BATS_TEST_TMPDIR/elsewhere/gone" "$SKILLS/mine"
  run "$CLI" sync --remove
  [ "$status" -eq 0 ]
  [ ! -L "$SKILLS/retired-skill" ]
  [ -L "$SKILLS/mine" ]
}

@test "doctor warns about a dangling symlink into the harness skills/ by name" {
  "$CLI" sync >/dev/null
  ln -s "$REPO/skills/git/retired-skill" "$SKILLS/retired-skill"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"retired-skill"*"sync"* ]] || false
}
