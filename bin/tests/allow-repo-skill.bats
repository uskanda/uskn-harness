#!/usr/bin/env bats
# Tests for the allow-repo skill's body (spec: allow-repo-skill). Inside the sandbox, Bash writes only to the
# directories the session added, so after recording the exception the skill tells the user to run /add-dir; the
# skill never adds the directory itself (ADR-0009).
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SKILL="$REPO/skills/allow-repo/SKILL.md"

frontmatter() { sed -n '2,/^---$/p' "$SKILL"; }

@test "allow-repo cannot be invoked by the model" {
  frontmatter | grep -qx 'disable-model-invocation: true'
}

@test "the report after recording tells the user to run /add-dir with the resolved path" {
  grep -qE '/add-dir <resolved path>' "$SKILL"
}

@test "the skill says it never runs /add-dir itself" {
  grep -qiE 'never run(s)? `/add-dir`|do not run `/add-dir`' "$SKILL"
}
