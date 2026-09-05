#!/usr/bin/env bats
# Tests for hooks/scripts/journal-update.sh (spec: journal-skeleton).
S="$BATS_TEST_DIRNAME/../scripts"; SCRIPT="$S/journal-update.sh"
setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME/.ai-sessions"
  export USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"; unset USKN_SKIP_JOURNAL
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R"; ( cd "$R" && git init -q -b main && echo a > a.txt && git add -A && git commit -q -m init && git remote add origin git@github.com:uskanda/demo.git )
  SID="0123456789abcdef-0000-0000-0000-000000000000"
  TR="$BATS_TEST_DIRNAME/fixtures/transcript.jsonl"
  printf '{"session_id":"%s","cwd":"%s","hook_event_name":"SessionStart"}' "$SID" "$R" | "$S/session-baseline.sh"
  J="$HOME/.ai-sessions/uskanda__demo"
}
stop() { printf '{"session_id":"%s","cwd":"%s","transcript_path":"%s","hook_event_name":"Stop","stop_hook_active":%s%s}' "$SID" "$R" "$TR" "${1:-false}" "${2:-}" | "$SCRIPT"; }
journal() { cat "$USKN_STATE_DIR/sessions/$SID/journal"; }

@test "creates the journal under <owner>__<repo>/<date>-<HHMM>-<sid8>.md and records its path" {
  run stop; [ "$status" -eq 0 ]
  [ -f "$(journal)" ]
  [[ "$(journal)" == "$J/"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]-01234567.md ]]
  grep -q "^session: $SID$" "$(journal)"; grep -q "^project: uskanda__demo$" "$(journal)"; grep -q "^branch: main$" "$(journal)"
  for h in "## Prompts" "## Changes" "## Commits" "## Skills" "<!-- agent -->" "## Decisions" "## Open" "## Next"; do grep -qF "$h" "$(journal)"; done
}

@test "prompts: user text only, 200 chars max, no tool results, no command echoes, <private> stripped" {
  stop >/dev/null; f="$(journal)"
  ! grep -q SECRET_TOOL_OUTPUT "$f"; ! grep -q "command-name" "$f"; ! grep -q hunter2 "$f"
  ! grep -q "Base directory for this skill" "$f"   # skill expansions (isMeta) are not prompts
  grep -q "ログイン画面を作って" "$f"; grep -q "Q1: A、Q2: B" "$f"
  n=$(sed -n '/^## Prompts/,/^## Changes/p' "$f" | grep -c '^- '); [ "$n" -eq 3 ]
  longest=$(sed -n '/^## Prompts/,/^## Changes/p' "$f" | grep '^- ' | awk '{ print length($0) }' | sort -n | tail -1); [ "$longest" -le 230 ]
}

@test "skills used are listed once each" {
  stop >/dev/null; f="$(journal)"
  sec=$(sed -n '/^## Skills/,/<!-- agent -->/p' "$f"); [ "$(echo "$sec" | grep -c '^- grilling$')" -eq 1 ]; echo "$sec" | grep -q '^- commit$'
}

@test "changes and commits since baseline appear" {
  echo b >> "$R/a.txt"; echo n > "$R/new.txt"; ( cd "$R" && git add a.txt && git commit -q -m "a を更新" )
  stop >/dev/null; f="$(journal)"
  grep -q "a.txt" "$f"; grep -q "new.txt" "$f"; grep -q "a を更新" "$f"
}

@test "agent sections survive regeneration" {
  stop >/dev/null; f="$(journal)"
  python3 - "$f" <<'PY'
import sys,re; p=sys.argv[1]; s=open(p).read(); s=s.replace("## Decisions\n","## Decisions\n- ログインは OAuth にする\n- セッションは 7 日\n",1); open(p,'w').write(s)
PY
  echo c > "$R/c.txt"; stop >/dev/null
  [ "$(grep -c 'ログインは OAuth にする' "$f")" -eq 1 ]; grep -q "c.txt" "$f"
}

@test "block once when the tree changed and Decisions is empty; never again in the session" {
  run stop; [ -z "$output" ]                                   # no change yet: silent
  echo z > "$R/z.txt"
  run stop; echo "$output" | jq -e '.decision == "block"' >/dev/null
  echo "$output" | jq -r .reason | grep -q "journal"; echo "$output" | jq -r .reason | grep -qF "$(journal)"
  [ -f "$USKN_STATE_DIR/sessions/$SID/journal-prompted" ]
  run stop; [ -z "$output" ]
}

@test "no block with Decisions filled, stop_hook_active, subagent, or USKN_SKIP_JOURNAL" {
  echo z > "$R/z.txt"
  run stop true; [ -z "$output" ]
  run stop false ',"agent_type":"Explore"'; [ -z "$output" ]
  USKN_SKIP_JOURNAL=1 run stop; [ -z "$output" ]
  python3 - "$(journal)" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read(); open(p,'w').write(s.replace("## Decisions\n","## Decisions\n- decided\n",1))
PY
  run stop; [ -z "$output" ]
}

@test "--path prints the journal path; --slug renames and sets the title, session stays" {
  stop >/dev/null; old="$(journal)"
  run "$SCRIPT" --session 01234567 --path; [ "$output" = "$old" ]
  run "$SCRIPT" --session 01234567 --slug add-login; [ "$status" -eq 0 ]
  new="$(journal)"; [[ "$new" == *-add-login.md ]]; [ -f "$new" ]; [ ! -e "$old" ]
  grep -q "^title: add-login$" "$new"; grep -q "^session: $SID$" "$new"
}

@test "--path before the first Stop says so; --ensure creates the journal now, idempotently, without blocking" {
  run "$SCRIPT" --session 01234567 --path; [ "$status" -eq 1 ]
  echo "$output" | grep -q "no journal yet"; echo "$output" | grep -q "ends normally"; echo "$output" | grep -q -- "--ensure"
  printf '%s\n' "$TR" > "$USKN_STATE_DIR/sessions/$SID/transcript"
  run "$SCRIPT" --session 01234567 --ensure; [ "$status" -eq 0 ]; [ -f "$output" ]; [ "$output" = "$(journal)" ]
  grep -q "^session: $SID$" "$output"; grep -q "^## Decisions" "$output"; grep -q "ログイン画面を作って" "$output"
  [ ! -e "$USKN_STATE_DIR/sessions/$SID/journal-prompted" ]
  run "$SCRIPT" --session 01234567 --ensure; [ "$status" -eq 0 ]; [ "$output" = "$(journal)" ]
  run "$SCRIPT" --session 01234567 --path; [ "$output" = "$(journal)" ]
}

@test "without ~/.ai-sessions nothing happens" {
  rm -rf "$HOME/.ai-sessions"
  run stop; [ "$status" -eq 0 ]; [ -z "$output" ]; [ ! -e "$USKN_STATE_DIR/sessions/$SID/journal" ]
}
