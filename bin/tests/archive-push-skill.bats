#!/usr/bin/env bats
# Tests for the archive-push skill's frontmatter (spec: archive-push-skill). archive-push ends in a push, which
# leaves the machine, so only the user may start it.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SKILL="$REPO/skills/archive-push/SKILL.md"

frontmatter() { sed -n '2,/^---$/p' "$SKILL"; }

@test "archive-push skill exists and is named archive-push" {
  [ -f "$SKILL" ]
  frontmatter | grep -qx 'name: archive-push'
}

@test "archive-push skill cannot be invoked by the model" {
  frontmatter | grep -qx 'disable-model-invocation: true'
}
