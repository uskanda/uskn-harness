#!/usr/bin/env bats
# Tests for hooks/scripts/journal-end.sh (spec: journal-sync).
S="$BATS_TEST_DIRNAME/../scripts"; SCRIPT="$S/journal-end.sh"
setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; export USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  git init -q --bare -b main "$BATS_TEST_TMPDIR/origin.git"
  git clone -q "$BATS_TEST_TMPDIR/origin.git" "$HOME/.ai-sessions" 2>/dev/null
  ( cd "$HOME/.ai-sessions" && git commit -q --allow-empty -m init && git push -q origin main )
  R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R"; ( cd "$R" && git init -q -b main && git commit -q --allow-empty -m init && git remote add origin https://github.com/o/r.git )
  SID="fedcba9876543210-0000-0000-0000-000000000000"; TR="$BATS_TEST_DIRNAME/fixtures/transcript.jsonl"
  printf '{"session_id":"%s","cwd":"%s"}' "$SID" "$R" | "$S/session-baseline.sh"
}
end() { printf '{"session_id":"%s","cwd":"%s","transcript_path":"%s","hook_event_name":"SessionEnd","reason":"prompt_input_exit"}' "$SID" "$R" "$TR" | "$SCRIPT"; }

@test "commits the journal and pushes it" {
  run end; [ "$status" -eq 0 ]
  ( cd "$HOME/.ai-sessions" && git log --oneline -1 | grep -q "o__r" && [ -z "$(git status --porcelain)" ] )
  git -C "$BATS_TEST_TMPDIR/origin.git" log --oneline -1 | grep -q "o__r"
}

@test "nothing new: no extra commit" {
  end >/dev/null; n1=$(git -C "$HOME/.ai-sessions" rev-list --count HEAD)
  end >/dev/null; n2=$(git -C "$HOME/.ai-sessions" rev-list --count HEAD); [ "$n1" -eq "$n2" ]
}

@test "push failure is tolerated: commit stays, exit 0" {
  ( cd "$HOME/.ai-sessions" && git remote set-url origin /nonexistent/origin.git )
  run end; [ "$status" -eq 0 ]
  git -C "$HOME/.ai-sessions" log --oneline -1 | grep -q "o__r"
}
