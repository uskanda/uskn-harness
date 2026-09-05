#!/usr/bin/env bats
# Tests for the Makefile's strict mode (spec: ci-verify). A PATH with only the shell basics makes every
# tool-dependent check skip; HOME is moved so the mise shims the Makefile prepends do not exist either.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

setup() {
  NOTOOLS="$BATS_TEST_TMPDIR/bin"; mkdir -p "$NOTOOLS" "$BATS_TEST_TMPDIR/home"
  local t p
  for t in make bash sh env grep sed awk find jq head tail wc sort uniq cut basename dirname cat tr xargs; do
    p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$NOTOOLS/$t"
  done
}
mk() { env -i HOME="$BATS_TEST_TMPDIR/home" PATH="$NOTOOLS" make -C "$REPO" "$@"; }

@test "default: a missing tool is reported as skipped and the target succeeds" {
  run mk verify-design
  [ "$status" -eq 0 ]; [[ "$output" == *"[design.md] skipped"* ]]
  run mk verify-textlint
  [ "$status" -eq 0 ]; [[ "$output" == *"[textlint] skipped"* ]]
}

@test "VERIFY_STRICT=1: a missing tool fails the target and names the check" {
  run mk verify-design VERIFY_STRICT=1
  [ "$status" -ne 0 ]; [[ "$output" == *"[design.md]"* ]]; [[ "$output" == *"VERIFY_STRICT"* ]]
  run mk verify-textlint VERIFY_STRICT=1
  [ "$status" -ne 0 ]; [[ "$output" == *"[textlint]"* ]]; [[ "$output" == *"VERIFY_STRICT"* ]]
  run mk verify-plugin VERIFY_STRICT=1
  [ "$status" -ne 0 ]; [[ "$output" == *"[plugin]"* ]]
}

@test "VERIFY_STRICT=0 behaves like the default" {
  run mk verify-design VERIFY_STRICT=0
  [ "$status" -eq 0 ]; [[ "$output" == *"skipped"* ]]
}
