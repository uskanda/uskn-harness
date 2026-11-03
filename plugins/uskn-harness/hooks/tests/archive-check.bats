#!/usr/bin/env bats
# Tests for hooks/scripts/archive-check.sh (spec: claude-plugin-packaging, the check for changes left unarchived).
# Each test builds a repository whose origin/main is a plain ref, so no remote and no network are involved.
SCRIPT="$BATS_TEST_DIRNAME/../scripts/archive-check.sh"

setup() {
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R/openspec/changes/archive/2026-01-01-done" "$R/openspec/changes/old-y"
  echo done > "$R/openspec/changes/archive/2026-01-01-done/proposal.md"
  echo old > "$R/openspec/changes/old-y/proposal.md"
  echo readme > "$R/README.md"
  ( cd "$R" && git init -q -b main && git add -A && git commit -qm base && git update-ref refs/remotes/origin/main HEAD \
      && git switch -q -c change/add-x )
}
commit_file() { # <path> <content>
  mkdir -p "$R/$(dirname "$1")"; printf '%s\n' "$2" > "$R/$1"
  ( cd "$R" && git add -A && git commit -qm "$1" )
}
check() { ( cd "$R" && "$SCRIPT" "$@" ); }

@test "no change touched: no output, exit 0" {
  commit_file README.md "edited"
  run check --base origin/main
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a change added on the branch is listed, exit 1" {
  commit_file openspec/changes/add-x/proposal.md "x"
  commit_file openspec/changes/add-x/specs/a/spec.md "a"
  run check --base origin/main
  [ "$status" -eq 1 ]
  [ "$output" = add-x ]
}

@test "several changes come one per line, sorted" {
  commit_file openspec/changes/zeta/proposal.md "z"
  commit_file openspec/changes/add-x/proposal.md "x"
  run check --base origin/main
  [ "$status" -eq 1 ]
  [ "$output" = "$(printf 'add-x\nzeta')" ]
}

@test "a change with .archive-later is left out" {
  commit_file openspec/changes/add-x/proposal.md "x"
  commit_file openspec/changes/add-x/.archive-later "follow-up work in #20"
  run check --base origin/main
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a change archived on the branch is left out" {
  commit_file openspec/changes/add-x/proposal.md "x"
  ( cd "$R" && mkdir -p openspec/changes/archive && git mv openspec/changes/add-x openspec/changes/archive/2026-11-03-add-x \
      && git commit -qm archive )
  run check --base origin/main
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "an active change the branch did not touch is left out; one it touched is listed" {
  commit_file openspec/changes/add-x/proposal.md "x"
  run check --base origin/main
  [ "$output" = add-x ]
  commit_file openspec/changes/old-y/tasks.md "- [x] 1.1 t"
  run check --base origin/main
  [ "$status" -eq 1 ]
  [ "$output" = "$(printf 'add-x\nold-y')" ]
}

@test "only HEAD counts: an uncommitted change is not listed" {
  mkdir -p "$R/openspec/changes/add-x"; echo x > "$R/openspec/changes/add-x/proposal.md"
  run check --base origin/main
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "the base moved on after the branch: only the branch's own changes count" {
  ( cd "$R" && git switch -q main && mkdir -p openspec/changes/main-z && echo z > openspec/changes/main-z/proposal.md \
      && git add -A && git commit -qm z && git update-ref refs/remotes/origin/main HEAD && git switch -q change/add-x )
  commit_file openspec/changes/add-x/proposal.md "x"
  run check --base origin/main
  [ "$status" -eq 1 ]
  [ "$output" = add-x ]
}

@test "a directory argument is checked instead of the current directory" {
  commit_file openspec/changes/add-x/proposal.md "x"
  run "$SCRIPT" --base origin/main "$R"
  [ "$status" -eq 1 ]
  [ "$output" = add-x ]
}

@test "cannot decide: a missing base, a missing --base, or no repository exit 2 with nothing on stdout" {
  run bash -c "cd '$R' && '$SCRIPT' --base origin/nowhere 2>/dev/null"
  [ "$status" -eq 2 ]
  [ -z "$output" ]
  run bash -c "cd '$R' && '$SCRIPT' 2>/dev/null"
  [ "$status" -eq 2 ]
  mkdir -p "$BATS_TEST_TMPDIR/plain"
  run bash -c "cd '$BATS_TEST_TMPDIR/plain' && '$SCRIPT' --base origin/main 2>/dev/null"
  [ "$status" -eq 2 ]
  [ -z "$output" ]
  run bash -c "cd '$R' && '$SCRIPT' --base origin/nowhere 2>&1 >/dev/null"
  [[ "$output" == *"origin/nowhere"* ]] || false
}

@test "openspec accepts .archive-later: validate passes and archive moves the file along" {
  command -v openspec >/dev/null || { [ "${VERIFY_STRICT:-0}" = 1 ] && false; skip "openspec not installed"; }
  local C="$R/openspec/changes/add-x"
  mkdir -p "$C/specs/thing"
  printf 'schema: spec-driven\ncreated: 2026-11-03\n' > "$C/.openspec.yaml"
  printf '# Proposal\n\n## Why\n\nA reason that is long enough for the validator to accept it as a real one.\n\n## What Changes\n\n- a thing\n' > "$C/proposal.md"
  printf '## ADDED Requirements\n\n### Requirement: Thing\nThe system SHALL do the thing.\n\n#### Scenario: Doing\n- **WHEN** asked\n- **THEN** it does the thing\n' > "$C/specs/thing/spec.md"
  printf '# Tasks\n\n- [x] 1.1 do it\n' > "$C/tasks.md"
  echo "follow-up work in #20" > "$C/.archive-later"
  run bash -c "cd '$R' && openspec validate add-x --strict --no-interactive"
  [ "$status" -eq 0 ]
  run bash -c "cd '$R' && openspec archive add-x --yes --skip-specs"
  [ "$status" -eq 0 ]
  moved="$(ls -d "$R"/openspec/changes/archive/*-add-x)"
  [ -f "$moved/.archive-later" ]
  [ ! -e "$C" ]
}
