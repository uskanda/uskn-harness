#!/usr/bin/env bats
# Tests for the verify skill's body (spec: verify-skill). Claude Code (2.1.286 and later) runs a user-level skill
# named verify right before each commit; the skill then runs verify-fast when the Makefile has it, and that run is
# never the evidence for a claim that work is done.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SKILL="$REPO/skills/verify/SKILL.md"

before_commit() { sed -n '/^## Right before a commit/,/^## /p' "$SKILL"; }

@test "verify has a section for the run right before a commit" {
  grep -q '^## Right before a commit' "$SKILL"
}

@test "that section runs verify-fast when the Makefile has it, else the convention" {
  before_commit | grep -q 'make verify-fast'
  before_commit | grep -qi 'otherwise'
}

@test "that section says the run is not evidence that the work is done" {
  before_commit | grep -qiE 'not (the )?evidence'
}
