#!/usr/bin/env bats
# Tests for the spec skill's finish (spec: spec-skill). It points at /opsx:apply only; spec-pr was retired (ADR-0016).
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SKILL="$REPO/skills/spec/SKILL.md"

@test "the finish points at /opsx:apply <name> and does not start it" {
  sed -n '/^### 5\. Finish/,/^## /p' "$SKILL" | grep -qF '`/opsx:apply <name>`'
  sed -n '/^### 5\. Finish/,/^## /p' "$SKILL" | grep -qi 'do not start it yourself'
}

@test "no word of the retired spec-pr skill is left" {
  run grep -n 'spec-pr' "$SKILL"
  [ "$status" -eq 1 ]
}
