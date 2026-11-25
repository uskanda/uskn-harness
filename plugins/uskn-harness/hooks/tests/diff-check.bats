#!/usr/bin/env bats
# Tests for hooks/scripts/diff-check.sh (spec: diff-check): removed tests, added skip markers, and changed verify
# settings in the diff from the merge-base of a ref to the working tree. Each test builds a repository whose
# origin/main is a plain ref, so no remote and no network are involved.
SCRIPT="$BATS_TEST_DIRNAME/../scripts/diff-check.sh"

setup() {
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R/tests" "$R/pkg" "$R/src" "$R/openspec/specs/x" "$R/.github/workflows"
  echo 'it("a", () => {})' > "$R/tests/a.test.ts"
  printf '@test "old" {\n  true\n}\n' > "$R/tests/old.bats"
  printf 'package pkg\n' > "$R/pkg/a_test.go"
  echo 'export const a = 1' > "$R/src/a.ts"
  echo '# spec' > "$R/openspec/specs/x/spec.md"
  printf 'verify:\n\ttrue\n' > "$R/Makefile"
  echo 'on: push' > "$R/.github/workflows/ci.yml"
  ( cd "$R" && git init -q -b main && git add -A && git commit -qm base && git update-ref refs/remotes/origin/main HEAD \
      && git switch -q -c change/add-x )
}
commit_all() { ( cd "$R" && git add -A && git commit -qm "$1" ); }
check() { ( cd "$R" && "$SCRIPT" "$@" ); }

@test "nothing to report: only source changed, no output, exit 0" {
  echo 'export const a = 2' > "$R/src/a.ts"; commit_all src
  run check --base origin/main
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a committed test deletion is reported, exit 1" {
  ( cd "$R" && git rm -q tests/a.test.ts && git commit -qm rm )
  run check --base origin/main
  [ "$status" -eq 1 ]
  [ "$output" = "test-deleted tests/a.test.ts" ]
}

@test "an uncommitted deletion of a tracked test is reported" {
  rm "$R/tests/a.test.ts"
  run check --base origin/main
  [ "$status" -eq 1 ]
  [ "$output" = "test-deleted tests/a.test.ts" ]
}

@test "a deleted file under openspec/ is not a test" {
  ( cd "$R" && git rm -q openspec/specs/x/spec.md && git commit -qm rm )
  run check --base origin/main
  [ "$status" -eq 0 ]
  [[ "$output" != *test-deleted* ]] || false
}

@test "a Go skip added to a test is reported with its line" {
  printf 'package pkg\nfunc TestA(t *testing.T) { t.Skip("later") }\n' > "$R/pkg/a_test.go"; commit_all skip
  run check --base origin/main
  [ "$status" -eq 1 ]
  [[ "$output" == "skip-added pkg/a_test.go: "*'t.Skip("later")'* ]] || false
}

@test "skip markers per kind: bats skip, .skip(, xit(, pytest" {
  printf '@test "old" {\n  skip "flaky"\n  true\n}\n' > "$R/tests/old.bats"
  echo 'it.skip("a", () => {}); xit("b", () => {})' > "$R/tests/a.test.ts"
  mkdir -p "$R/py"; printf 'import pytest\n@pytest.mark.skip\ndef test_a(): pass\n' > "$R/py/test_a.py"
  ( cd "$R" && git add tests && git commit -qm skip && git add py )
  run check --base origin/main
  [ "$status" -eq 1 ]
  [[ "$output" == *"skip-added tests/old.bats: "*"skip \"flaky\""* ]] || false
  [[ "$output" == *"skip-added tests/a.test.ts: "*"it.skip("* ]] || false
  [[ "$output" == *"skip-added py/test_a.py: @pytest.mark.skip"* ]] || false
}

@test "a test changed without a skip marker is not reported" {
  printf '@test "old" {\n  [ 1 -eq 1 ]\n}\n' > "$R/tests/old.bats"; commit_all edit
  run check --base origin/main
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "a changed verify setting is reported but keeps exit 0" {
  printf 'verify:\n\techo ok\n' > "$R/Makefile"
  echo 'on: [push, pull_request]' > "$R/.github/workflows/ci.yml"
  commit_all settings
  run check --base origin/main
  [ "$status" -eq 0 ]
  [[ "$output" == *"verify-setting Makefile"* ]] || false
  [[ "$output" == *"verify-setting .github/workflows/ci.yml"* ]] || false
}

@test "--allow-from leaves out deletions and skips the file names" {
  ( cd "$R" && git rm -q tests/old.bats && git commit -qm rm )
  printf -- '- [ ] 2.1 Remove tests/old.bats with the old parser\n' > "$BATS_TEST_TMPDIR/tasks.md"
  run check --base origin/main --allow-from "$BATS_TEST_TMPDIR/tasks.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "--allow-from keeps what the file does not name" {
  ( cd "$R" && git rm -q tests/old.bats tests/a.test.ts && git commit -qm rm )
  printf -- '- [ ] 2.1 Remove tests/old.bats\n' > "$BATS_TEST_TMPDIR/tasks.md"
  run check --base origin/main --allow-from "$BATS_TEST_TMPDIR/tasks.md"
  [ "$status" -eq 1 ]
  [ "$output" = "test-deleted tests/a.test.ts" ]
}

@test "an untracked new test with a skip is not read" {
  echo 'it.skip("n", () => {})' > "$R/tests/new.test.ts"
  run check --base origin/main
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "DIR names the work tree to check" {
  ( cd "$R" && git rm -q tests/a.test.ts && git commit -qm rm )
  run "$SCRIPT" --base origin/main "$R"
  [ "$status" -eq 1 ]
  [ "$output" = "test-deleted tests/a.test.ts" ]
}

@test "no such ref: exit 2, nothing on stdout" {
  run bash -c "cd '$R' && '$SCRIPT' --base origin/nowhere 2>/dev/null"
  [ "$status" -eq 2 ]
  [ -z "$output" ]
}

@test "missing --base or outside a work tree: exit 2" {
  run check
  [ "$status" -eq 2 ]
  run "$SCRIPT" --base origin/main "$BATS_TEST_TMPDIR"
  [ "$status" -eq 2 ]
}
