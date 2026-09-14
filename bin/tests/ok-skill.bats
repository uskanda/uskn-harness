#!/usr/bin/env bats
# Tests for the ok skill's frontmatter (spec: ok-skill). ok stands for the user's approval, so only the user may
# invoke it; the agent must not approve its own proposal.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SKILL="$REPO/skills/ok/SKILL.md"

frontmatter() { sed -n '2,/^---$/p' "$SKILL"; }

@test "ok skill exists and is named ok" {
  [ -f "$SKILL" ]
  frontmatter | grep -qx 'name: ok'
}

@test "ok skill cannot be invoked by the model" {
  frontmatter | grep -qx 'disable-model-invocation: true'
}
