#!/usr/bin/env bats
# Tests for the sandbox-exclude skill (spec: sandbox-exclude-skill). Taking a command out of the sandbox loosens a
# guard, so only the user invokes the skill; it runs `uskn-harness sandbox-exclude` and keeps execution whose effect
# cannot be read beforehand inside the sandbox unless the user insists (ADR-0011).
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SKILL="$REPO/skills/sandbox-exclude/SKILL.md"

frontmatter() { sed -n '2,/^---$/p' "$SKILL"; }

@test "sandbox-exclude exists, is named sandbox-exclude, and only the user can invoke it" {
  [ -f "$SKILL" ]
  frontmatter | grep -qx 'name: sandbox-exclude'
  frontmatter | grep -qx 'disable-model-invocation: true'
  frontmatter | grep -q '^argument-hint:'
}

@test "the skill runs uskn-harness sandbox-exclude as a standalone command and shows the list" {
  grep -qF 'uskn-harness sandbox-exclude' "$SKILL"
  grep -qF -- '--list' "$SKILL"
  grep -qiE 'standalone|on its own' "$SKILL"
}

@test "the skill has a step that keeps execution whose effect cannot be read beforehand in the sandbox" {
  grep -q '^### .*[Ee]xecution' "$SKILL"
  for t in npm make python; do grep -qF "\`$t\`" "$SKILL"; done
}
