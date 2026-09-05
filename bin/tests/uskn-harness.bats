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
  [ -L "$HOME/.local/share/openspec/schemas/uskn" ] && [ "$(readlink -f "$HOME/.local/share/openspec/schemas/uskn")" = "$REPO/schemas/uskn" ]
  [ -f "$CLAUDE_CONFIG_DIR/CLAUDE.md" ] && head -1 "$CLAUDE_CONFIG_DIR/CLAUDE.md" | grep -q "managed by uskn-harness"
  grep -q "mise use -g node@24" "$USKN_HARNESS_STUB_LOG"
  grep -q "openspec@1.12.0" "$USKN_HARNESS_STUB_LOG"
  grep -q "skills@latest add mattpocock/skills --skill grilling" "$USKN_HARNESS_STUB_LOG"
  grep -q "git clone --quiet https://github.com/uskanda/ai-sessions.git $HOME/.ai-sessions" "$USKN_HARNESS_STUB_LOG"
  [[ "$output" == *"created"* ]]
}

@test "sync --tools installs the runtime, the pinned CLIs, and the schema link only; --tools --remove exits 2" {
  run "$CLI" sync --tools
  [ "$status" -eq 0 ]
  grep -q "mise use -g node@24" "$USKN_HARNESS_STUB_LOG"
  grep -q "openspec@1.12.0" "$USKN_HARNESS_STUB_LOG"
  [ -L "$HOME/.local/share/openspec/schemas/uskn" ] && [ "$(readlink -f "$HOME/.local/share/openspec/schemas/uskn")" = "$REPO/schemas/uskn" ]
  [ ! -e "$STABLE" ] && [ ! -e "$HOME/.local/bin/uskn-harness" ]
  [ ! -e "$SKILLS/commit" ] && [ ! -e "$SKILLS/uskn-harness" ] && [ ! -e "$CLAUDE_CONFIG_DIR/CLAUDE.md" ] && [ ! -e "$HOME/.ai-sessions" ]
  ! grep -q "git clone" "$USKN_HARNESS_STUB_LOG"; ! grep -q "skills@latest add" "$USKN_HARNESS_STUB_LOG"; ! grep -q "openspec-user-layer" "$USKN_HARNESS_STUB_LOG"
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
  [ ! -e "$SKILLS/commit" ] && [ ! -e "$SKILLS/uskn-harness" ] && [ ! -e "$HOME/.local/bin/uskn-harness" ] && [ ! -e "$STABLE" ] && [ ! -e "$HOME/.local/share/openspec/schemas/uskn" ]
  [ -d "$SKILLS/keepme" ]
  [ ! -e "$CLAUDE_CONFIG_DIR/CLAUDE.md" ]
}

@test "existing ~/.ai-sessions git repo is left alone and reported ok" {
  mkdir -p "$HOME/.ai-sessions/.git"
  run "$CLI" sync
  [[ "$output" == *"ok"*"sessions repo"* ]]
  ! grep -q "ai-sessions" "$USKN_HARNESS_STUB_LOG"
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

# ---- phase 3: pinned npm CLIs (textlint, agent-style, design.md) and UI skills (spec: harness-sync, harness-doctor)

@test "sync installs the pinned npm CLIs with their bundles and the UI / writing skills from deps.json" {
  run "$CLI" sync
  [ "$status" -eq 0 ]
  grep -q "npm install -g textlint@15.8.0 textlint-rule-preset-ja-technical-writing@12.0.2 @textlint-ja/textlint-rule-preset-ai-writing@1.7.0" "$USKN_HARNESS_STUB_LOG"
  grep -q "npm install -g agent-style@0.4.2" "$USKN_HARNESS_STUB_LOG"
  grep -q "npm install -g @google/design.md@0.4.0" "$USKN_HARNESS_STUB_LOG"
  grep -q "impeccable@4.0.1 install" "$USKN_HARNESS_STUB_LOG"
  grep -q "skills@latest add anthropics/claude-plugins-official --skill frontend-design" "$USKN_HARNESS_STUB_LOG"
  for s in ja-writing en-writing ui-guidelines test-driven-development systematic-debugging verification-before-completion using-git-worktrees; do
    [ -L "$SKILLS/$s" ] && [ "$(readlink -f "$SKILLS/$s")" = "$REPO/skills/$s" ]
  done
}

@test "sync skips an npm CLI whose package and bundle are already at the pinned versions" {
  export USKN_NPM_ROOT="$BATS_TEST_TMPDIR/npm"
  for p in textlint:15.8.0 textlint-rule-preset-ja-technical-writing:12.0.2 @textlint-ja/textlint-rule-preset-ai-writing:1.7.0 \
           textlint-rule-preset-jtf-style:3.0.3 textlint-rule-prh:6.1.0 agent-style:0.4.2; do
    mkdir -p "$USKN_NPM_ROOT/${p%%:*}"; printf '{"version":"%s"}\n' "${p##*:}" > "$USKN_NPM_ROOT/${p%%:*}/package.json"
  done
  run "$CLI" sync
  [ "$status" -eq 0 ]
  ! grep -q "textlint@15.8.0" "$USKN_HARNESS_STUB_LOG"
  ! grep -q "agent-style@0.4.2" "$USKN_HARNESS_STUB_LOG"
  grep -q "@google/design.md@0.4.0" "$USKN_HARNESS_STUB_LOG"
  [[ "$output" == *"ok"*"textlint 15.8.0"* ]]
}

@test "doctor warns about a missing or mismatched npm CLI and reports the pinned version" {
  export USKN_NPM_ROOT="$BATS_TEST_TMPDIR/npm"
  mkdir -p "$USKN_NPM_ROOT/textlint"; echo '{"version":"15.0.0"}' > "$USKN_NPM_ROOT/textlint/package.json"
  run "$CLI" doctor
  [[ "$output" == *"warn"*"textlint"*"15.0.0"*"15.8.0"* ]]
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
  [[ "$output" != *"ok "* ]] || true
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
    [ "$status" -eq 0 ]; ! grep -q "pull --ff-only" "$USKN_HARNESS_STUB_LOG"
  done
  : > "$USKN_HARNESS_STUB_LOG"
  USKN_HARNESS_DIR="$WORK" run "$CLI" sync --dry-run
  [ "$status" -eq 0 ]; [[ "$output" == *"plan"* ]]; [[ "$output" == *"pull --ff-only"* ]]
  ! grep -q "pull --ff-only" "$USKN_HARNESS_STUB_LOG"
}
