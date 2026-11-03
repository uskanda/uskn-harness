#!/usr/bin/env bats
# Tests for archiving before an integrating operation (spec: git-workflow-skills; ADR-0014). The pr and push skills
# run uskn-archive-check before they integrate, run archive-push for each change it lists, and write the
# archive-later declaration when the user says a change waits.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
PR="$REPO/skills/git/pr/SKILL.md"
PUSH="$REPO/skills/git/push/SKILL.md"

@test "pr and push run uskn-archive-check, then archive-push through the Skill tool" {
  for f in "$PR" "$PUSH"; do
    grep -qF 'uskn-archive-check --base origin/' "$f" || { echo "no uskn-archive-check in $f"; false; }
    grep -qF 'Run the Skill tool with `archive-push`' "$f" || { echo "no archive-push call in $f"; false; }
    grep -qF '.archive-later' "$f" || { echo "no .archive-later in $f"; false; }
  done
}

@test "pr runs the check before its push, in the integration and custom modes only" {
  sec="$(sed -n '/^## Archive before integrating/,/^## /p' "$PR")"
  [ -n "$sec" ]
  grep -qi 'integration' <<<"$sec"
  grep -qi 'custom' <<<"$sec"
  grep -qi 'release' <<<"$sec"
  # the step comes before the GitHub section, whose first command is the push
  [ "$(grep -n '^## Archive before integrating' "$PR" | cut -d: -f1)" -lt "$(grep -n '^## GitHub' "$PR" | cut -d: -f1)" ]
}

@test "push runs the check before step 5, for the default and the integration branch only" {
  a="$(grep -n 'uskn-archive-check' "$PUSH" | head -1 | cut -d: -f1)"
  b="$(grep -n '^### 5\. Push' "$PUSH" | cut -d: -f1)"
  [ -n "$a" ] && [ -n "$b" ]
  [ "$a" -lt "$b" ]
}

@test "a stopped archive-push stops the integrating operation" {
  for f in "$PR" "$PUSH"; do
    grep -qiE 'archive-push` stops' "$f" || { echo "no stop rule in $f"; false; }
  done
}
