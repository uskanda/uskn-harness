#!/usr/bin/env bats
# Tests for the spec-pr skill's frontmatter (spec: spec-pr-skill). spec-pr opens a draft spec PR on the user's
# request, so the model may invoke it too; unlike archive-push it carries no disable-model-invocation.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SKILL="$REPO/skills/spec-pr/SKILL.md"

frontmatter() { sed -n '2,/^---$/p' "$SKILL"; }

@test "spec-pr skill exists and is named spec-pr" {
  [ -f "$SKILL" ]
  frontmatter | grep -qx 'name: spec-pr'
}

@test "spec-pr skill can be invoked by the model" {
  [ -f "$SKILL" ]
  ! frontmatter | grep -q '^disable-model-invocation: *true'
}

@test "spec-pr's body template shows how to run the loop on the spec PR" {
  sed -n '/^## 進め方/,/^```$/p' "$SKILL" | grep -qF '`uskn-loop run <このPRの番号>`'
}
