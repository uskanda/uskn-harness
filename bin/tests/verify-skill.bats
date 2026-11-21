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

diff_section() { sed -n '/^## Removed or skipped tests/,/^## /p' "$SKILL"; }

@test "verify has a section that runs the diff check before a claim and before a pull request" {
  grep -q '^## Removed or skipped tests' "$SKILL"
  diff_section | grep -qF 'uskn-diff-check --base origin/'
  diff_section | grep -qi 'pull request'
}

@test "that section passes the active change's tasks.md with --allow-from" {
  diff_section | grep -qF -- '--allow-from'
  diff_section | grep -qF 'tasks.md'
}

@test "that section says what to do with each exit code and with verify-setting lines" {
  diff_section | grep -qF 'test-deleted'
  diff_section | grep -qF 'verify-setting'
  diff_section | grep -qE 'exit (code )?2|Exit 2|`2`'
}
