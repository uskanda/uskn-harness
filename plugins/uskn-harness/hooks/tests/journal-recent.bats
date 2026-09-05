#!/usr/bin/env bats
# Tests for hooks/scripts/journal-recent.sh (spec: journal-context).
S="$BATS_TEST_DIRNAME/../scripts"; SCRIPT="$S/journal-recent.sh"
setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; J="$HOME/.ai-sessions/o__r"; mkdir -p "$J"
  export GIT_CONFIG_GLOBAL=/dev/null
  R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R"; ( cd "$R" && git init -q -b main && git remote add origin git@github.com:o/r.git )
  for i in 1 2 3 4 5; do
    printf -- '---\nsession: s%s\nproject: o__r\ntitle: work-%s\n---\n\n# work-%s\n\n## Prompts\n- p\n\n<!-- agent -->\n## Decisions\n- decision %s\n\n## Open\n- open %s\n\n## Next\n- next %s\n' $i $i $i $i $i $i > "$J/2026-09-0$i-1200-s$i.md"
  done
}
fire() { printf '{"session_id":"%s","cwd":"%s","hook_event_name":"SessionStart","source":"startup"}' "${1:-new}" "$R" | "$SCRIPT"; }

@test "newest three journals, with title, Decisions, and Next" {
  run fire; [ "$status" -eq 0 ]
  [[ "$output" == "<recent-sessions>"* ]]
  for i in 5 4 3; do [[ "$output" == *"work-$i"* ]] && [[ "$output" == *"decision $i"* ]] && [[ "$output" == *"next $i"* ]]; done
  [[ "$output" != *"work-2"* ]]; [[ "$output" != *"open 5"* ]]
}

@test "the current session's own journal is skipped" {
  run fire s5; [[ "$output" != *"work-5"* ]]; [[ "$output" == *"work-2"* ]]
}

@test "no journals: no output" {
  rm -rf "$J"; run fire; [ "$status" -eq 0 ]; [ -z "$output" ]
}
