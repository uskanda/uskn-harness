#!/usr/bin/env bats
# Tests for hooks/scripts/session-start.sh (spec: session-context-hook, branch-model).
# Each test builds throwaway git repositories under $BATS_TEST_TMPDIR; nothing touches $HOME.

SCRIPT="$BATS_TEST_DIRNAME/../scripts/session-start.sh"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"   # keep gh/glab configs out of the picture
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
}

# make_repo <dir> <remote-url> [extra-branches...]
# Creates a bare origin, clones it (so origin/HEAD exists), pushes main plus any extra branches,
# then points origin at <remote-url> so hosting detection sees a realistic URL.
make_repo() {
  local dir="$1" url="$2"; shift 2
  local bare="$dir.git"
  git init -q --bare -b main "$bare"
  git clone -q "$bare" "$dir" 2>/dev/null
  ( cd "$dir" && git commit -q --allow-empty -m init && git push -q origin main && git remote set-head origin main
    for b in "$@"; do git branch -q "$b" && git push -q origin "$b"; done
    git fetch -q origin && git remote set-url origin "$url" )
}

json_cwd() { printf '{"session_id":"s","cwd":"%s","hook_event_name":"SessionStart"}' "$1"; }

@test "outside a git repository: no output, exit 0" {
  mkdir -p "$BATS_TEST_TMPDIR/plain"
  run bash -c "echo '$(json_cwd "$BATS_TEST_TMPDIR/plain")' | '$SCRIPT'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "empty stdin falls back to PWD" {
  make_repo "$BATS_TEST_TMPDIR/r" git@github.com:o/r.git
  run bash -c "cd '$BATS_TEST_TMPDIR/r' && '$SCRIPT' </dev/null"
  [ "$status" -eq 0 ]
  [[ "$output" == *"<repo-context>"* ]]
  [[ "$output" == *"platform: github"* ]]
}

@test "hosting: github.com remote is github with reason" {
  make_repo "$BATS_TEST_TMPDIR/r" git@github.com:o/r.git
  run "$SCRIPT" --plain hosting "$BATS_TEST_TMPDIR/r"
  [ "$status" -eq 0 ]
  [ "$output" = "github" ]
  run "$SCRIPT" --json "$BATS_TEST_TMPDIR/r"
  [[ "$output" == *'"hosting_reason":"known host"'* ]]
}

@test "hosting: self-hosted gitlab host name" {
  make_repo "$BATS_TEST_TMPDIR/r" https://gitlab.example.co.jp/g/r.git
  run "$SCRIPT" --plain hosting "$BATS_TEST_TMPDIR/r"
  [ "$output" = "gitlab" ]
}

@test "hosting: no remote and no CI files is unknown, context asks skills to decide" {
  mkdir -p "$BATS_TEST_TMPDIR/r" && ( cd "$BATS_TEST_TMPDIR/r" && git init -q -b main && git commit -q --allow-empty -m init )
  run "$SCRIPT" --plain hosting "$BATS_TEST_TMPDIR/r"
  [ "$output" = "unknown" ]
  run "$SCRIPT" "$BATS_TEST_TMPDIR/r"
  [[ "$output" == *"decide"* ]]
}

@test "hosting: .github/workflows without remote hints github" {
  mkdir -p "$BATS_TEST_TMPDIR/r/.github/workflows" && ( cd "$BATS_TEST_TMPDIR/r" && git init -q -b main && git commit -q --allow-empty -m init )
  run "$SCRIPT" --plain hosting "$BATS_TEST_TMPDIR/r"
  [ "$output" = "github" ]
}

@test "branches: origin/HEAD main with develop and qa" {
  make_repo "$BATS_TEST_TMPDIR/r" git@github.com:o/r.git develop qa
  run "$SCRIPT" --plain branches "$BATS_TEST_TMPDIR/r"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "default=main" ]
  [ "${lines[1]}" = "integration=develop" ]
  [ "${lines[2]}" = "qa=qa" ]
  [ "${lines[3]}" = "release_tag=calver" ]
  [ "${#lines[@]}" -eq 4 ]
}

@test "branches: main only -> integration is main, qa empty" {
  make_repo "$BATS_TEST_TMPDIR/r" git@github.com:o/r.git
  run "$SCRIPT" --plain branches "$BATS_TEST_TMPDIR/r"
  [ "${lines[1]}" = "integration=main" ]
  [ "${lines[2]}" = "qa=" ]
  run "$SCRIPT" "$BATS_TEST_TMPDIR/r"
  [[ "$output" == *"qa: (none)"* ]]
}

@test "branches: origin/HEAD master" {
  local bare="$BATS_TEST_TMPDIR/r.git"
  git init -q --bare -b master "$bare" && git clone -q "$bare" "$BATS_TEST_TMPDIR/r" 2>/dev/null
  ( cd "$BATS_TEST_TMPDIR/r" && git commit -q --allow-empty -m init && git push -q origin master && git remote set-head origin master && git remote set-url origin git@github.com:o/r.git )
  run "$SCRIPT" --plain branches "$BATS_TEST_TMPDIR/r"
  [ "${lines[0]}" = "default=master" ]
  [ "${lines[1]}" = "integration=master" ]
}

@test "branches: no origin/HEAD falls back to origin/main and says so" {
  mkdir -p "$BATS_TEST_TMPDIR/r" && ( cd "$BATS_TEST_TMPDIR/r" && git init -q -b main && git commit -q --allow-empty -m init \
    && git remote add origin git@github.com:o/r.git && git update-ref refs/remotes/origin/main HEAD )
  run "$SCRIPT" --plain branches "$BATS_TEST_TMPDIR/r"
  [ "${lines[0]}" = "default=main" ]
  run "$SCRIPT" "$BATS_TEST_TMPDIR/r"
  [[ "$output" == *"default: main (origin/main exists)"* ]]
}

@test "AGENTS.md overrides integration only; other keys stay detected" {
  make_repo "$BATS_TEST_TMPDIR/r" git@github.com:o/r.git develop qa
  cat > "$BATS_TEST_TMPDIR/r/AGENTS.md" <<'MD'
# repo

## Branch model

```yaml
integration: trunk   # comment
```

## Other
MD
  run "$SCRIPT" --plain branches "$BATS_TEST_TMPDIR/r"
  [ "${lines[0]}" = "default=main" ]
  [ "${lines[1]}" = "integration=trunk" ]
  [ "${lines[2]}" = "qa=qa" ]
  run "$SCRIPT" "$BATS_TEST_TMPDIR/r"
  [[ "$output" == *"integration: trunk (AGENTS.md)"* ]]
  [[ "$output" == *"default: main (origin/HEAD)"* ]]
}

@test "AGENTS.md qa: none disables qa; quoted values are unquoted" {
  make_repo "$BATS_TEST_TMPDIR/r" git@github.com:o/r.git develop qa
  printf '## Branch model\n\n```yaml\nqa: none\nrelease_tag: "semver"\n```\n' > "$BATS_TEST_TMPDIR/r/AGENTS.md"
  run "$SCRIPT" --plain branches "$BATS_TEST_TMPDIR/r"
  [ "${lines[2]}" = "qa=" ]
  [ "${lines[3]}" = "release_tag=semver" ]
}

@test "AGENTS.md without the heading changes nothing" {
  make_repo "$BATS_TEST_TMPDIR/r" git@github.com:o/r.git develop
  printf '# repo\n\n```yaml\nintegration: nope\n```\n' > "$BATS_TEST_TMPDIR/r/AGENTS.md"
  run "$SCRIPT" --plain branches "$BATS_TEST_TMPDIR/r"
  [ "${lines[1]}" = "integration=develop" ]
}

@test "--json is one valid object with the same values" {
  make_repo "$BATS_TEST_TMPDIR/r" git@github.com:o/r.git develop
  run "$SCRIPT" --json "$BATS_TEST_TMPDIR/r"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.platform == "github" and .default == "main" and .integration == "develop" and .qa == "" and .release_tag == "calver"' >/dev/null
}

@test "context block names the top-level directory, remote, and the no-redetect rule" {
  make_repo "$BATS_TEST_TMPDIR/r" git@github.com:o/r.git
  run bash -c "echo '$(json_cwd "$BATS_TEST_TMPDIR/r")' | '$SCRIPT'"
  [[ "$output" == "<repo-context>"* ]]
  [[ "$output" == *"</repo-context>" ]]
  [[ "$output" == *"git@github.com:o/r.git"* ]]
  [[ "$output" == *"Use these values"* ]]
}

@test "works without jq on PATH (stdin cwd still parsed)" {
  make_repo "$BATS_TEST_TMPDIR/r" git@github.com:o/r.git
  local fakebin="$BATS_TEST_TMPDIR/bin"; mkdir -p "$fakebin"
  for t in bash sh git sed awk grep cat head tail tr cut date dirname basename readlink mktemp printf env sort uniq wc; do
    p="$(command -v "$t")" && ln -s "$p" "$fakebin/$t"
  done
  run env PATH="$fakebin" bash -c "echo '$(json_cwd "$BATS_TEST_TMPDIR/r")' | '$SCRIPT'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"platform: github"* ]]
  run env PATH="$fakebin" "$SCRIPT" --json "$BATS_TEST_TMPDIR/r"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"platform":"github"'* ]]
}
