#!/usr/bin/env bats
# Tests over every skill (spec: claude-plugin-packaging, skills call the short commands). A skill runs the plugin's
# helper scripts through the commands in plugins/uskn-harness/bin, never through the long hooks/scripts/ path. A uskn-*
# command a skill names is one of those, or an executable in bin/ that sync puts on PATH (uskn-harness, uskn-loop).
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

@test "no skill calls session-start.sh or terms-check.sh by the hooks/scripts/ path" {
  run grep -rlE 'hooks/scripts/(session-start|terms-check)\.sh' "$REPO/skills" --include=SKILL.md
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "every uskn-* command a skill names is in the repository's bin/ or the plugin's bin/" {
  names="$(grep -rhoE '\buskn-[a-z0-9]+(-[a-z0-9]+)*' "$REPO/skills" --include=SKILL.md | sort -u)"
  [ -n "$names" ]
  while read -r n; do
    [ -x "$REPO/bin/$n" ] || [ -x "$REPO/plugins/uskn-harness/bin/$n" ] || { echo "no such command: $n"; false; }
  done <<< "$names"
}

@test "the skills that need repository context or the terms check use the short commands" {
  grep -q 'uskn-repo-context' "$REPO/skills/git/push/SKILL.md"
  grep -q 'uskn-terms-check' "$REPO/skills/audit-writing/SKILL.md"
}
