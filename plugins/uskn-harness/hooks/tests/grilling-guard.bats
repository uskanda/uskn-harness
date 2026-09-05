#!/usr/bin/env bats
# Tests for hooks/scripts/grilling-guard.sh (spec: grilling-guard).

SCRIPT="$BATS_TEST_DIRNAME/../scripts/grilling-guard.sh"

setup() {
  R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R/openspec/changes/add-x/specs/foo" "$R/openspec/changes/archive/2026-01-01-old" "$R/openspec/specs/foo" "$R/src"
  ( cd "$R" && git init -q -b main )
}

# call <tool_name> <file_path> [cwd]
call() { printf '{"session_id":"s","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":{"file_path":"%s","content":"x"}}' "${3:-$R}" "$1" "$2" | "$SCRIPT"; }

@test "proposal without grilling.md is denied with a reason naming grilling.md" {
  run call Write "$R/openspec/changes/add-x/proposal.md"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
  echo "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -q "grilling.md"
}

@test "design, tasks, and specs are denied too, for Edit and NotebookEdit" {
  for f in design.md tasks.md specs/foo/spec.md; do
    run call Edit "$R/openspec/changes/add-x/$f"
    echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
  done
  run call NotebookEdit "$R/openspec/changes/add-x/tasks.md"
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
}

@test "with grilling.md present nothing is printed" {
  touch "$R/openspec/changes/add-x/grilling.md"
  run call Write "$R/openspec/changes/add-x/proposal.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "writing grilling.md itself is allowed" {
  run call Write "$R/openspec/changes/add-x/grilling.md"
  [ -z "$output" ]
}

@test "archive, main specs, and files outside changes are ignored" {
  run call Edit "$R/openspec/changes/archive/2026-01-01-old/tasks.md"; [ -z "$output" ]
  run call Edit "$R/openspec/specs/foo/spec.md"; [ -z "$output" ]
  run call Write "$R/src/app.ts"; [ -z "$output" ]
}

@test "relative paths resolve against cwd" {
  run call Write "openspec/changes/add-x/proposal.md" "$R"
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
  run bash -c "cd '$R/src' && printf '{\"cwd\":\"%s\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"../openspec/changes/add-x/tasks.md\"}}' '$R/src' | '$SCRIPT'"
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
}

@test "broken stdin or missing file_path exits 0 silently" {
  run bash -c "echo 'not json' | '$SCRIPT'"; [ "$status" -eq 0 ]; [ -z "$output" ]
  run bash -c "printf '{\"tool_name\":\"Write\",\"tool_input\":{}}' | '$SCRIPT'"; [ "$status" -eq 0 ]; [ -z "$output" ]
}
