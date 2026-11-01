#!/usr/bin/env bats
# Tests for the sandbox-allow-host skill (spec: sandbox-allow-host-skill). Letting the sandbox reach a host loosens a
# guard, so only the user invokes the skill; it runs `uskn-harness sandbox-allow-host` with the host name alone and
# never adds a * (ADR-0012).
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
SKILL="$REPO/skills/sandbox-allow-host/SKILL.md"

frontmatter() { sed -n '2,/^---$/p' "$SKILL"; }

@test "sandbox-allow-host exists, is named sandbox-allow-host, and only the user can invoke it" {
  [ -f "$SKILL" ]
  frontmatter | grep -qx 'name: sandbox-allow-host'
  frontmatter | grep -qx 'disable-model-invocation: true'
  frontmatter | grep -q '^argument-hint:'
}

@test "the skill runs uskn-harness sandbox-allow-host as a standalone command and shows the list" {
  grep -qF 'uskn-harness sandbox-allow-host' "$SKILL"
  grep -qF -- '--list' "$SKILL"
  grep -qiE 'standalone|on its own' "$SKILL"
}

@test "the skill takes the host name out of a URL" {
  grep -q '^### .*[Hh]ost' "$SKILL"
  grep -qF 'https://' "$SKILL"
  grep -qiE 'path' "$SKILL"
}

@test "the skill never adds a * and points at WebFetch(domain:*)" {
  grep -qF 'WebFetch(domain:*)' "$SKILL"
  grep -qiE 'add nothing' "$SKILL"
}
