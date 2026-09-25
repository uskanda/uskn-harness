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
# skill <dir> <description line>: a SKILL.md whose frontmatter carries that raw description line
skill() { mkdir -p "$1"; printf -- '---\nname: %s\n%s\n---\n\n# body\n' "$(basename "$1")" "$2" > "$1/SKILL.md"; }
has_yaml() { python3 -c 'import yaml' >/dev/null 2>&1; }

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

@test "verify-terms without python3: skipped by default, a failure under VERIFY_STRICT=1" {
  run mk verify-terms
  [ "$status" -eq 0 ]; [[ "$output" == *"skipped"* ]]
  run mk verify-terms VERIFY_STRICT=1
  [ "$status" -ne 0 ]; [[ "$output" == *"[terms]"* ]]; [[ "$output" == *"VERIFY_STRICT"* ]]
}

@test "verify-skills parses every frontmatter as YAML: an unquoted colon fails and names the file" {
  has_yaml || skip "python3 with PyYAML is not available"
  fx="$BATS_TEST_TMPDIR/skills"
  skill "$fx/good" 'description: Do a thing - argument is a name.'
  skill "$fx/git/bad" 'description: Do a thing. Optional argument: a name.'
  run make -C "$REPO" verify-skills SKILLS_DIR="$fx"
  [ "$status" -ne 0 ]
  [[ "$output" == *"$fx/git/bad/SKILL.md"* ]]
  [[ "$output" != *"$fx/good/SKILL.md"* ]]
}

@test "verify-skills: a name that differs from the directory and an empty description fail" {
  has_yaml || skip "python3 with PyYAML is not available"
  fx="$BATS_TEST_TMPDIR/skills"
  skill "$fx/one" 'description: ""'
  mkdir -p "$fx/two"; printf -- '---\nname: other\ndescription: x\n---\n' > "$fx/two/SKILL.md"
  run make -C "$REPO" verify-skills SKILLS_DIR="$fx"
  [ "$status" -ne 0 ]
  [[ "$output" == *"one/SKILL.md"*"description"* ]]
  [[ "$output" == *"two/SKILL.md"*"name"* ]]
}

@test "verify-skills passes on this repository's skills" {
  has_yaml || skip "python3 with PyYAML is not available"
  run make -C "$REPO" verify-skills
  [ "$status" -eq 0 ]
  [[ "$output" == *"[skills]"* ]]
}

@test "verify-skills without PyYAML: skipped by default, a failure under VERIFY_STRICT=1" {
  run mk verify-skills
  [ "$status" -eq 0 ]; [[ "$output" == *"skipped"* ]]
  run mk verify-skills VERIFY_STRICT=1
  [ "$status" -ne 0 ]; [[ "$output" == *"[skills]"* ]]; [[ "$output" == *"VERIFY_STRICT"* ]]
}

@test "VERIFY_STRICT=0 behaves like the default" {
  run mk verify-design VERIFY_STRICT=0
  [ "$status" -eq 0 ]; [[ "$output" == *"skipped"* ]]
}
