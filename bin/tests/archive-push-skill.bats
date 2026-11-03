#!/usr/bin/env bats
# Tests for the archive-push skill (spec: archive-push-skill). The user runs it as /archive-push, and the pr and push
# skills run it before an integrating operation (ADR-0014), so the model may invoke it.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SKILL="$REPO/skills/archive-push/SKILL.md"

frontmatter() { sed -n '2,/^---$/p' "$SKILL"; }
body() { sed '1,/^---$/d' "$SKILL"; }

@test "archive-push skill exists and is named archive-push" {
  [ -f "$SKILL" ]
  frontmatter | grep -qx 'name: archive-push'
}

@test "archive-push skill can be invoked by the model" {
  [ -f "$SKILL" ]
  ! frontmatter | grep -q '^disable-model-invocation:'
}

@test "archive-push never picks a change that carries an archive-later declaration" {
  body | grep -qF '.archive-later'
}
