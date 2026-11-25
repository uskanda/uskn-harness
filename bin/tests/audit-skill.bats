#!/usr/bin/env bats
# Tests for the audit skill (spec: audit-skill). It runs as a fork, without the conversation that implemented the
# change, and judges an OpenSpec change against its specs and the computational checks (ADR-0016).
REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
DIR="$REPO/skills/audit"
SKILL="$DIR/SKILL.md"

frontmatter() { sed -n '2,/^---$/p' "$SKILL" | sed '$d'; }
field() { frontmatter | sed -n "s/^$1: *//p" | head -1; }
body() { sed '1,/^---$/d' "$SKILL" | sed '1,/^---$/d'; }

@test "audit exists and is named audit" {
  [ -f "$SKILL" ]
  [ "$(field name)" = audit ]
}

@test "audit runs as a fork that the caller waits for" {
  [ "$(field context)" = fork ]
  [ "$(field background)" = false ]
}

@test "audit may read and run commands, and nothing else" {
  [ "$(field allowed-tools)" = "Bash, Read, Grep, Glob" ]
}

@test "audit carries its auditor brief and the verdict shape" {
  [ -f "$DIR/references/auditor.md" ]
  [ -f "$DIR/references/verdict.schema.json" ]
  jq -e '.required == ["verdict", "scenarios", "findings", "question"]' "$DIR/references/verdict.schema.json" >/dev/null
  grep -qF 'references/auditor.md' "$SKILL"
  grep -qF 'references/verdict.schema.json' "$SKILL"
}

@test "audit names the commands it runs: the archive check for its targets and the diff check" {
  grep -qF 'uskn-archive-check --base origin/' "$SKILL"
  grep -qF 'uskn-diff-check --base origin/' "$SKILL"
  grep -qF -- '--allow-from' "$SKILL"
  grep -qF 'openspec validate' "$SKILL"
}

@test "audit stops on uncommitted changes and leaves tracked files as it found them" {
  grep -qF 'git status --porcelain' "$SKILL"
  grep -qiE 'restore|git restore' "$SKILL"
}

@test "audit keeps style findings out of the blocking set" {
  grep -qiE 'skip style|style.*advisory|advisory.*style' "$DIR/references/auditor.md"
}
