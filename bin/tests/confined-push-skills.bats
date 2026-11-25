#!/usr/bin/env bats
# Tests for stopping before the remote in the confined environment (specs: git-workflow-skills, spec-pr-skill,
# archive-push-skill). The five skills that write to the remote run uskn-environment before their first remote write,
# and on `confined` stop there and report that the push and the pull request happen outside the confined environment.
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SKILLS="git/push git/pr git/release spec-pr archive-push"

# The first line that writes to the remote: a push, a pull or merge request, a release, or the push skill.
first_remote_write() { # <SKILL.md>
  grep -nE 'git push|gh pr create|glab mr create|gh release create|glab release create|Skill tool with `push`' "$1" |
    head -1 | cut -d: -f1
}

@test "each skill that writes to the remote runs uskn-environment before its first remote write" {
  for s in $SKILLS; do
    f="$REPO/skills/$s/SKILL.md"
    e="$(grep -n 'uskn-environment' "$f" | head -1 | cut -d: -f1)"
    w="$(first_remote_write "$f")"
    [ -n "$e" ] || { echo "no uskn-environment in $s"; false; }
    [ -n "$w" ] || { echo "no remote write in $s"; false; }
    [ "$e" -lt "$w" ] || { echo "uskn-environment (line $e) comes after the first remote write (line $w) in $s"; false; }
  done
}

@test "on confined each skill stops before the remote and says the outside pushes" {
  for s in $SKILLS; do
    f="$REPO/skills/$s/SKILL.md"
    grep -qF '`confined`' "$f" || { echo "no \`confined\` branch in $s"; false; }
    tr -s ' \n' '  ' <"$f" | grep -qiF 'outside the confined environment' || { echo "no report of the outside push in $s"; false; }
  done
}

@test "the commit skill has no environment check: it commits in the confined environment too" {
  ! grep -qF 'uskn-environment' "$REPO/skills/git/commit/SKILL.md"
}
