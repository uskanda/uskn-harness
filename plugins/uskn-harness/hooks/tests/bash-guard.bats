#!/usr/bin/env bats
# Tests for hooks/scripts/bash-guard.sh (spec: bash-guard).
SCRIPT="$BATS_TEST_DIRNAME/../scripts/bash-guard.sh"
setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; export USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"; mkdir -p "$HOME/dotfiles" "$USKN_STATE_DIR/sessions/sid12345678"
  export GIT_CONFIG_GLOBAL=/dev/null
  ROOT="$BATS_TEST_TMPDIR/repos/a"; OTHER="$BATS_TEST_TMPDIR/repos/b"; mkdir -p "$ROOT" "$OTHER"; ( cd "$ROOT" && git init -q -b main )
  export CLAUDE_PROJECT_DIR="$ROOT"
}
call() { jq -c -n --arg c "$1" --arg cwd "$ROOT" '{session_id:"sid12345678", cwd:$cwd, tool_name:"Bash", tool_input:{command:$c}}' | "$SCRIPT"; }
denied() { echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null; }
warned() { echo "$output" | jq -e '(.hookSpecificOutput.permissionDecision // "none") == "none" and (.hookSpecificOutput.additionalContext | length) > 0' >/dev/null; }

@test "chezmoi apply / add / update are denied" {
  for c in "chezmoi apply --force" "chezmoi add ~/.claude/settings.json" "chezmoi update"; do run call "$c"; [ "$status" -eq 0 ]; denied; done
}

@test "git writes in another repo are denied: cd form and -C form, with ~ expansion" {
  run call "cd ~/dotfiles && git push origin master"; denied
  run call "git -C $OTHER commit -am x"; denied
  run call "cd $OTHER; git checkout -b feat"; denied
}

@test "git reads in another repo and git writes in the root are silent" {
  run call "git -C ~/dotfiles log --oneline -3"; [ -z "$output" ]
  run call "git -C $OTHER status"; [ -z "$output" ]
  run call "git push origin main"; [ -z "$output" ]
  run call "cd $ROOT && git commit -m x"; [ -z "$output" ]
}

@test "copies, moves, redirects to outside paths only warn" {
  run call "cp x.md $OTHER/"; [ "$status" -eq 0 ]; warned
  run call "echo hi > $OTHER/f.txt"; warned
  run call "sed -i 's/a/b/' ~/dotfiles/x"; warned
  run call "cp a b"; [ -z "$output" ]
}

@test "session allow file makes that repo writable" {
  echo "$OTHER" > "$USKN_STATE_DIR/sessions/sid12345678/allow"
  run call "git -C $OTHER commit -am x"; [ -z "$output" ]
  run call "cp x $OTHER/"; [ -z "$output" ]
}

@test "broken input: silent exit 0" {
  run bash -c "echo nope | '$SCRIPT'"; [ "$status" -eq 0 ]; [ -z "$output" ]
}
