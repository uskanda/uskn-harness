#!/usr/bin/env bats
# Tests for the plugin's bin/ (spec: claude-plugin-packaging, the short commands for skills). Claude Code puts
# <plugin>/bin on the Bash tool's PATH; each command runs its hook script with the same arguments.
BIN="$BATS_TEST_DIRNAME/../../bin"
SCRIPTS="$BATS_TEST_DIRNAME/../scripts"

setup() {
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R/docs" "$R/openspec"
  printf 'version: 1\nterms: []\n' > "$R/openspec/glossary.yml"
  ( cd "$R" && git init -q -b main && git remote add origin git@github.com:o/r.git && git add -A && git commit -qm init )
}

@test "bin/ holds uskn-repo-context and uskn-terms-check, executable, and nothing else" {
  [ -x "$BIN/uskn-repo-context" ]
  [ -x "$BIN/uskn-terms-check" ]
  [ "$(ls "$BIN" | sort | tr '\n' ' ')" = "uskn-repo-context uskn-terms-check " ]
}

@test "uskn-repo-context gives what session-start.sh gives, in every mode" {
  for mode in "--plain hosting" "--plain branches" "--json"; do
    # shellcheck disable=SC2086
    expected="$("$SCRIPTS/session-start.sh" $mode "$R")"
    # shellcheck disable=SC2086
    run "$BIN/uskn-repo-context" $mode "$R"
    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ]
  done
  run bash -c "cd '$R' && PATH='$BIN':\"\$PATH\" uskn-repo-context --plain hosting </dev/null"
  [ "$output" = github ]
}

@test "uskn-terms-check keeps the findings and the exit code of terms-check.sh" {
  printf '# t\n\nSee `nowhere-at-all.yaml`.\n' > "$R/docs/ng.md"
  run bash -c "cd '$R' && '$BIN/uskn-terms-check' docs/ng.md"
  [ "$status" -eq 1 ]
  [[ "$output" == *"nowhere-at-all.yaml"* ]]
  printf '# t\n\nNothing to report.\n' > "$R/docs/ok.md"
  run bash -c "cd '$R' && '$BIN/uskn-terms-check' docs/ok.md"
  [ "$status" -eq 0 ]
}

@test "the commands work through a symlinked plugin directory, as sync installs it" {
  mkdir -p "$HOME/.claude/skills"
  ln -s "$(cd "$BIN/.." && pwd)" "$HOME/.claude/skills/uskn-harness"
  run "$HOME/.claude/skills/uskn-harness/bin/uskn-repo-context" --plain hosting "$R"
  [ "$status" -eq 0 ]
  [ "$output" = github ]
}
