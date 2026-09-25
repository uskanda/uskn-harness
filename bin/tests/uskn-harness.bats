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
  # The session state sync prunes lives under the fake HOME, never the real ~/.local/state.
  export XDG_STATE_HOME="$HOME/.local/state"; unset USKN_STATE_DIR
  mkdir -p "$HOME/.local/bin" "$CLAUDE_CONFIG_DIR/skills"
  : > "$USKN_HARNESS_STUB_LOG"
  SKILLS="$CLAUDE_CONFIG_DIR/skills"
  STABLE="$HOME/.local/share/uskn-harness"
}

snapshot() { ( cd "$HOME" && find . -printf '%p %y %l\n' | sort ); }
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

@test "--help prints usage and exits 0" {
  run "$CLI" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"sync"* ]]
  [[ "$output" == *"doctor"* ]]
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
  [[ "$output" != *"sessions repo"* ]]
  [[ "$output" == *"created"* ]]
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
  run "$CLI" sync --tools; [ "$status" -eq 0 ]; [[ "$output" == *"ok"*"openspec schema uskn"* ]]
  run "$CLI" sync --tools --remove; [ "$status" -eq 2 ]
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
  [ ! -L "$SKILLS/commit" ]
  [ "$(cat "$SKILLS/commit/SKILL.md")" = old ]
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

@test "the reserved skill name uskn-harness aborts with exit 2 before any write" {
  fx="$BATS_TEST_TMPDIR/fx"; mkdir -p "$fx/skills/a/uskn-harness" "$fx/skills/b/fine" "$fx/plugins/uskn-harness" "$fx/templates/user" "$fx/bin"
  printf -- '---\nname: uskn-harness\ndescription: x\n---\n' > "$fx/skills/a/uskn-harness/SKILL.md"
  printf -- '---\nname: fine\ndescription: x\n---\n' > "$fx/skills/b/fine/SKILL.md"
  cp "$REPO/deps.json" "$fx/deps.json"; cp "$CLI" "$fx/bin/uskn-harness"; echo '<!-- managed by uskn-harness -->' > "$fx/templates/user/CLAUDE.md"
  before="$(snapshot)"
  USKN_HARNESS_DIR="$fx" run "$CLI" sync
  [ "$status" -eq 2 ]
  [[ "$output" == *"reserved"* ]]
  [ "$(snapshot)" = "$before" ]
}

@test "a failed step: sync finishes the other steps, reports on stderr, and exits 1" {
  USKN_HARNESS_STUB_FAIL='npm global textlint' run "$CLI" sync
  [ "$status" -eq 1 ]
  [[ "$output" == *"fail"*"npm global textlint"* ]]
  [[ "$output" == *"run 'uskn-harness sync' again"* ]]
  [ -L "$SKILLS/commit" ]
  [ -f "$CLAUDE_CONFIG_DIR/CLAUDE.md" ]
  run "$CLI" sync
  [ "$status" -eq 0 ]
}

@test "sync --tools exits 1 when a pinned CLI fails to install" {
  USKN_HARNESS_STUB_FAIL='npm global *' run "$CLI" sync --tools
  [ "$status" -eq 1 ]
  [[ "$output" == *"fail"*"npm global"* ]]
}

@test "a failed checkout update is a warning: sync still exits 0" {
  make_checkout; advance_origin one
  USKN_HARNESS_DIR="$WORK" USKN_HARNESS_STUB_FAIL='harness pull*' run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"harness pull"* ]]
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
  before="$( cd "$HOME/.ai-sessions" && find . -printf '%p %y %s %T@\n' | sort )"
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" != *"ai-sessions"* ]]
  [[ "$output" != *"sessions repo"* ]]
  refute grep -q "ai-sessions" "$USKN_HARNESS_STUB_LOG"
  run "$CLI" doctor
  [[ "$output" != *"ai-sessions"* ]]
  [[ "$output" != *"sessions repo"* ]]
  [ "$( cd "$HOME/.ai-sessions" && find . -printf '%p %y %s %T@\n' | sort )" = "$before" ]
}

@test "doctor does not ask for a sessions repo when ~/.ai-sessions is missing" {
  "$CLI" sync >/dev/null
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" != *"sessions repo"* ]]
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
  [[ "$output" == *"plan"*"$st/old"* ]]
  [[ "$output" != *"$st/old-dir-new-file"* ]]
  [[ "$output" != *"$st/recent"* ]]
  run "$CLI" sync --tools
  [ "$status" -eq 0 ]
  [ -d "$st/old" ]
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ ! -e "$st/old" ]
  [ -d "$st/recent" ]
  [ -d "$st/old-dir-new-file" ]
  [[ "$output" == *"removed"*"session state"* ]]
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [[ "$output" != *"removed"* ]]
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
  [[ "$output" == *"plan"*"$SKILLS/retired-skill"* ]]
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ ! -L "$SKILLS/retired-skill" ]
  [[ "$output" == *"removed"*"retired-skill"* ]]
  [ -L "$SKILLS/mine" ]
  [[ "$output" != *"retired skill link mine "* ]]
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

@test "templates/user/CLAUDE.md names no skill the harness has retired" {
  for s in verification-before-completion using-git-worktrees pre-merge nessun-dorma; do
    refute grep -q -- "$s" "$REPO/templates/user/CLAUDE.md"
  done
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
  [[ "$output" == *"ok"*"textlint $(dep .clis.textlint.version)"* ]]
}

@test "doctor warns about a missing or mismatched npm CLI and reports the pinned version" {
  export USKN_NPM_ROOT="$BATS_TEST_TMPDIR/npm"
  mkdir -p "$USKN_NPM_ROOT/textlint"; echo '{"version":"15.0.0"}' > "$USKN_NPM_ROOT/textlint/package.json"
  run "$CLI" doctor
  [ "$(dep .clis.textlint.version)" != 15.0.0 ]
  [[ "$output" == *"warn"*"textlint"*"15.0.0"*"$(dep .clis.textlint.version)"* ]]
  [[ "$output" == *"warn"*"agent-style"*"none"* ]]
  [[ "$output" == *"warn"*"third-party impeccable"* ]]
}

# ---- phase 4: onboard-check (spec: onboard-check)

fixture_repo() { # <dir> [ui]  -- a bare product repo, optionally with a UI dependency
  mkdir -p "$1"; ( cd "$1" && git init -q -b main )
  [ "${2:-}" = ui ] && printf '{"dependencies":{"expo":"~54.0.0","react":"19.1.0"}}\n' > "$1/package.json"
  return 0
}
onboarded_repo() { # <dir> -- everything onboard-harness would place, with a UI dependency
  fixture_repo "$1" ui
  printf '# product\n' > "$1/AGENTS.md"
  printf '@AGENTS.md\n' > "$1/CLAUDE.md"
  mkdir -p "$1/openspec/specs" "$1/openspec/changes"; printf 'schema: uskn\n' > "$1/openspec/config.yaml"
  printf 'verify:\n\t@echo ok\n' > "$1/Makefile"
  printf '%s\n' '---' 'name: x' '---' > "$1/DESIGN.md"; printf '# Product\n' > "$1/PRODUCT.md"
}

@test "onboard-check on an untouched repo warns about every item and still exits 0" {
  P="$BATS_TEST_TMPDIR/fresh"; fixture_repo "$P" ui
  run "$CLI" onboard-check "$P"
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"AGENTS.md"* ]]
  [[ "$output" == *"warn"*"CLAUDE.md"* ]]
  [[ "$output" == *"warn"*"openspec"* ]]
  [[ "$output" == *"warn"*"verify"* ]]
  [[ "$output" == *"warn"*"DESIGN.md"* ]]
  [[ "$output" == *"warn"*"PRODUCT.md"* ]]
  refute grep -q '^ok ' <<<"$output"
}

@test "onboard-check on an onboarded repo reports ok for every item" {
  P="$BATS_TEST_TMPDIR/done"; onboarded_repo "$P"
  run "$CLI" onboard-check "$P"
  [ "$status" -eq 0 ]
  [[ "$output" != *"warn"* ]]
  [[ "$output" == *"ok"*"AGENTS.md"* ]]
  [[ "$output" == *"ok"*"schema: uskn"* ]]
  [[ "$output" == *"ok"*"make verify"* ]]
}

@test "onboard-check writes nothing into the target repository" {
  P="$BATS_TEST_TMPDIR/ro"; onboarded_repo "$P"
  before="$( cd "$P" && find . -not -path './.git/*' -printf '%p %s\n' | sort )"
  run "$CLI" onboard-check "$P"
  [ "$status" -eq 0 ]
  [ "$( cd "$P" && find . -not -path './.git/*' -printf '%p %s\n' | sort )" = "$before" ]
}

@test "onboard-check skips DESIGN.md and PRODUCT.md when the repo has no UI dependency" {
  P="$BATS_TEST_TMPDIR/noui"; fixture_repo "$P"
  run "$CLI" onboard-check "$P"
  [ "$status" -eq 0 ]
  [[ "$output" != *"DESIGN.md"* ]]
  [[ "$output" != *"PRODUCT.md"* ]]
  [[ "$output" == *"AGENTS.md"* ]]
}

@test "onboard-check warns when a project skill shadows a user-layer skill" {
  P="$BATS_TEST_TMPDIR/dup"; onboarded_repo "$P"
  mkdir -p "$P/.claude/skills/commit" "$P/.claude/skills/release-expo" "$SKILLS/commit"
  run "$CLI" onboard-check "$P"
  [ "$status" -eq 0 ]
  [[ "$output" == *"commit"* ]]
  [[ "$output" == *"warn"* ]]
  [[ "$output" != *"warn"*"release-expo"* ]]
}

@test "onboard-check warns when CLAUDE.md does not point at AGENTS.md" {
  P="$BATS_TEST_TMPDIR/stale"; onboarded_repo "$P"
  printf '# rules\n\n色々書いてある\n' > "$P/CLAUDE.md"
  run "$CLI" onboard-check "$P"
  [[ "$output" == *"warn"*"CLAUDE.md"* ]]
}

@test "onboard-check defaults to the current directory and reports the path" {
  P="$BATS_TEST_TMPDIR/cwd"; onboarded_repo "$P"
  run bash -c "cd '$P' && '$CLI' onboard-check"
  [ "$status" -eq 0 ]
  [[ "$output" == *"$P"* ]]
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
  [ "$status" -eq 0 ]; [[ "$output" == *"updated"* ]]
  [ "$(head_of)" != "$before" ]; [ -f "$WORK/marker.txt" ]
}

@test "update: already current says so and pulls nothing new" {
  make_checkout; before="$(head_of)"
  update
  [ "$status" -eq 0 ]; [[ "$output" == *"up to date"* ]]; [ "$(head_of)" = "$before" ]
}

@test "update: uncommitted changes, detached HEAD, and a branch without upstream all skip" {
  make_checkout; advance_origin one; before="$(head_of)"
  echo dirt >> "$WORK/deps.json"
  update; [[ "$output" == *"uncommitted"* ]]; [ "$(head_of)" = "$before" ]
  git -C "$WORK" checkout -q -- deps.json
  git -C "$WORK" checkout -q --detach
  update; [[ "$output" == *"detached"* ]]; [ "$(head_of)" = "$before" ]
  git -C "$WORK" checkout -q main && git -C "$WORK" checkout -q -b local-only
  update; [[ "$output" == *"upstream"* ]]; [ "$(head_of)" = "$before" ]
}

@test "update: a diverged checkout is never merged; it reports the failure and returns 0" {
  make_checkout; advance_origin one
  ( cd "$WORK" && echo x > local.txt && git add -A && git commit -qm local )
  before="$(head_of)"
  update
  [ "$status" -eq 0 ]; [ "$(head_of)" = "$before" ]; [[ "$output" == *"fail"* ]]
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
  [ "$status" -eq 0 ]; [[ "$output" == *"plan"* ]]; [[ "$output" == *"pull --ff-only"* ]]
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
  [[ "$output" == *"created"*"openspec commands opsx"* ]]
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
  [[ "$output" == *"plan"*"remove $SKILLS/openspec-propose"* ]]
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ ! -e "$SKILLS/openspec-propose" ]
  [[ "$output" == *"removed"*"openspec-propose"* ]]
  [ "$(cat "$SKILLS/openspec-explore/SKILL.md")" = mine ]
}

@test "doctor: the six openspec commands are ok; openspec-* skills are no longer checked" {
  "$CLI" sync >/dev/null
  opsx_commands "$CLAUDE_CONFIG_DIR/commands/opsx"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"*"openspec commands opsx"* ]]
  [[ "$output" != *"openspec skill"* ]]
}

@test "doctor: a missing openspec command, a missing marker, or no commands at all is warn with the name" {
  "$CLI" sync >/dev/null
  O="$CLAUDE_CONFIG_DIR/commands/opsx"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"openspec commands opsx"*"missing"*"sync"* ]]
  opsx_commands "$O"; rm "$O/archive.md"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"openspec commands opsx"*"archive"*"sync"* ]]
  echo x > "$O/archive.md"; rm "$O/.uskn-harness-managed"
  run "$CLI" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"warn"*"openspec commands opsx"*"not harness-managed"* ]]
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
  [[ "$output" == *"plan"*"remove $SKILLS/retired-skill"* ]]
  [[ "$output" != *"remove $SKILLS/pr"* ]]
  run "$CLI" sync
  [ "$status" -eq 0 ]
  [ ! -L "$SKILLS/retired-skill" ]
  [ ! -L "$SKILLS/retired-too" ]
  [[ "$output" == *"removed"*"retired-skill"* ]]
  [ -L "$SKILLS/mine" ]
  [ -d "$SKILLS/real" ]
  [[ "$output" == *"updated"*"pr"* ]]
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
  [[ "$output" == *"warn"*"retired-skill"*"sync"* ]]
}
