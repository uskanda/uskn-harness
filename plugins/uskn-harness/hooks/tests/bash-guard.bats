#!/usr/bin/env bats
# Tests for hooks/scripts/bash-guard.sh (spec: bash-guard).
SCRIPT="$BATS_TEST_DIRNAME/../scripts/bash-guard.sh"
setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; export USKN_STATE_DIR="$BATS_TEST_TMPDIR/state"; mkdir -p "$HOME/dotfiles" "$USKN_STATE_DIR/sessions/sid12345678"
  export GIT_CONFIG_GLOBAL=/dev/null
  # The default allowlist (/tmp, $TMPDIR) would cover BATS_TEST_TMPDIR itself, wherever TMPDIR points; use a dedicated one.
  SCRATCH="$BATS_TEST_TMPDIR/scratch"; export USKN_GUARD_ALLOW_DIRS="$SCRATCH"
  ROOT="$BATS_TEST_TMPDIR/repos/a"; OTHER="$BATS_TEST_TMPDIR/repos/b"; mkdir -p "$ROOT" "$OTHER" "$SCRATCH"; ( cd "$ROOT" && git init -q -b main )
  export CLAUDE_PROJECT_DIR="$ROOT"
}
call() { jq -c -n --arg c "$1" --arg cwd "$ROOT" '{session_id:"sid12345678", cwd:$cwd, tool_name:"Bash", tool_input:{command:$c}}' | "$SCRIPT"; }
denied() { echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null; }
warned() { echo "$output" | jq -e '(.hookSpecificOutput.permissionDecision // "none") == "none" and (.hookSpecificOutput.additionalContext | length) > 0' >/dev/null; }
reason() { echo "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason'; }
# refute <command...>: fails when the command succeeds (a bare `! cmd` mid-test never fails a bats test).
refute() { ! "$@"; }
# path_without <cmd>: PATH minus every directory that holds <cmd>
path_without() {
  local d out="" IFS=:
  for d in $PATH; do [ -x "$d/$1" ] || out="${out:+$out:}$d"; done
  printf '%s' "$out"
}

@test "chezmoi apply / add / update are denied" {
  for c in "chezmoi apply --force" "chezmoi add ~/.claude/settings.json" "chezmoi update"; do
    run call "$c"
    [ "$status" -eq 0 ]
    denied
  done
}

@test "git writes in another repo are denied: cd form and -C form, with ~ expansion" {
  run call "cd ~/dotfiles && git push origin master"; denied
  run call "git -C $OTHER commit -am x"; denied
  run call "cd $OTHER; git checkout -b feat"; denied
}

@test "chezmoi: options before the subcommand are skipped; read-only subcommands are silent" {
  run call "chezmoi -v apply"; denied
  run call "chezmoi --source ~/dotfiles --verbose re-add ~/.zshrc"; denied
  run call "cd /tmp && chezmoi --dry-run -v merge ~/.bashrc"; denied
  run call "chezmoi diff"; [ -z "$output" ]
  run call "chezmoi cat ~/.bashrc"; [ -z "$output" ]
  run call "chezmoi source-path"; [ -z "$output" ]
}

@test "chezmoi: the deny names the source directory; allowing that directory lifts it" {
  fake="$BATS_TEST_TMPDIR/bin"; mkdir -p "$fake"
  printf '#!/usr/bin/env bash\n[ "$1" = source-path ] && echo "%s"\n' "$HOME/dotfiles" > "$fake/chezmoi"; chmod +x "$fake/chezmoi"
  PATH="$fake:$PATH" run call "chezmoi apply"; denied
  reason | grep -qF "/allow-repo $HOME/dotfiles"
  echo "$HOME/dotfiles" > "$USKN_STATE_DIR/sessions/sid12345678/allow"
  PATH="$fake:$PATH" run call "chezmoi apply --force"; [ -z "$output" ]
  PATH="$fake:$PATH" run call "chezmoi -v re-add"; [ -z "$output" ]
  PATH="$fake:$PATH" run call "chezmoi -S $OTHER apply"; denied   # an explicit source elsewhere is not covered
}

@test "chezmoi: without the binary the source directory is ~/.local/share/chezmoi, compared by its real path" {
  mkdir -p "$HOME/.local/share"; ln -s "$HOME/dotfiles" "$HOME/.local/share/chezmoi"
  P="$(path_without chezmoi)"
  PATH="$P" run call "chezmoi apply"; denied
  reason | grep -qF "/allow-repo $HOME/.local/share/chezmoi"
  echo "$HOME/dotfiles" > "$USKN_STATE_DIR/sessions/sid12345678/allow"
  PATH="$P" run call "chezmoi apply"; [ -z "$output" ]
}

@test "chezmoi: the project root and the fixed allowlist do not lift the deny" {
  fake="$BATS_TEST_TMPDIR/bin"; mkdir -p "$fake"
  printf '#!/usr/bin/env bash\n[ "$1" = source-path ] && echo "%s"\n' "$ROOT" > "$fake/chezmoi"; chmod +x "$fake/chezmoi"
  PATH="$fake:$PATH" run call "chezmoi apply"; denied
}

@test "git writes in another repo: quoted paths, options before -C, --git-dir, GIT_DIR, pushd, relative cd" {
  run call "git -C \"$OTHER\" push"; denied
  run call "cd '$OTHER' && git push"; denied
  run call "git -c k=v -C $OTHER commit -m x"; denied
  run call "git --git-dir=$OTHER/.git commit -m x"; denied
  run call "git --work-tree $OTHER --git-dir $OTHER/.git reset --hard"; denied
  run call "GIT_DIR=$OTHER/.git git commit -m x"; denied
  run call "pushd $OTHER && git commit -m x"; denied
  run call "cd ../b && git push"; denied
  run call "{ cd $OTHER; git push; }"; denied
}

@test "reads and writes that stay in the root are silent: git log --grep, a subshell cd, heredoc bodies" {
  run call "git -C $OTHER log --grep reset"; [ -z "$output" ]
  run call "git -C $OTHER show HEAD:push.txt"; [ -z "$output" ]
  run call "(cd $OTHER && git log) && git commit -m x"; [ -z "$output" ]
  run call $'git commit -F - <<\'EOF\'\ncd ~/dotfiles && git push\necho x > /etc/passwd\nEOF'; [ -z "$output" ]
  run call "$(printf 'git commit -m "$(cat <<%s\nsubject\n\ncd %s && git push; chezmoi apply\nEOF\n)"' "'EOF'" "$OTHER")"; [ -z "$output" ]
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

@test "quoted redirect targets and writes after cd into an outside directory warn" {
  run call "echo hi > \"$OTHER/f\""; warned
  run call "make 2>>'$OTHER/log'"; warned
  run call "cd $OTHER && touch f"; warned
  run call "mv $OTHER/a.txt ./"; warned
  run call "tee -a $OTHER/x < in.txt"; warned
}

@test "sed expressions, copies from outside, and links to outside targets are not outside writes" {
  run call "sed -i -n '/,\$p' file"; [ -z "$output" ]
  run call "sed -i 's/.*foo//' file"; [ -z "$output" ]
  run call "sed -i -e 's#/x#/y#' -e '/^\$/d' notes.md"; [ -z "$output" ]
  run call "sed -n '/,\$p' $OTHER/x"; [ -z "$output" ]
  run call "cp $OTHER/x.md ./"; [ -z "$output" ]
  run call "ln -s $OTHER/x.md link"; [ -z "$output" ]
  run call "make verify 2>&1 | tail -n 40"; [ -z "$output" ]
}

@test "the session allow file: naming it or writing to it is denied; running allow-repo.sh is silent" {
  A="$USKN_STATE_DIR/sessions/sid12345678/allow"
  run call "echo $OTHER >> $A"; denied
  reason | grep -qF "allow-repo.sh --list"
  run call "cp list.txt '$A'"; denied
  run call "python3 -c \"open('$A','a').write('/x')\""; denied
  run call "cat ~/.local/state/uskn-harness/sessions/other/allow"; denied
  ln -s "$USKN_STATE_DIR/sessions/sid12345678" "$SCRATCH/sess"
  run call "echo /x > $SCRATCH/sess/allow"; denied
  run call "cd $USKN_STATE_DIR/sessions/sid12345678 && echo /x >> allow"; denied
  echo "$USKN_STATE_DIR" > "$A"
  run call "echo /x >> $A"; denied
  run call "\"\$HOME/.local/share/uskn-harness/plugins/uskn-harness/hooks/scripts/allow-repo.sh\" --session sid12345 $OTHER"; [ -z "$output" ]
  run call "cat $USKN_STATE_DIR/sessions/sid12345678/verify.log"; [ -z "$output" ]
}

@test "the verify gate's state: naming, writing, or removing it is denied; the log and ordinary copies are not" {
  S="$USKN_STATE_DIR/sessions/sid12345678"
  run call "echo x > $S/verified"; denied
  reason | grep -q "USKN_SKIP_VERIFY"
  run call "cat ~/.local/state/uskn-harness/sessions/abc123/baseline"; denied
  run call "python3 -c \"open('$S/verify-blocks','w').write('3')\""; denied
  run call "rm -rf $S"; denied
  run call "cp $SCRATCH/baseline $S/"; denied
  run call "mv $S $SCRATCH/old"; denied
  run call "rm -rf $USKN_STATE_DIR"; denied
  run call "rm -rf $USKN_STATE_DIR/sessions"; denied
  run call "cd $S && rm verified"; denied
  echo "$USKN_STATE_DIR" > "$S/allow"
  run call "touch $S/baseline"; denied
  run call "tail -n 40 $S/verify.log"; [ -z "$output" ]
  run call "cat ~/.local/state/uskn-harness/sessions/abc123/baseline-head"; [ -z "$output" ]
  run call "cp x.md $BATS_TEST_TMPDIR/"; refute denied   # a copy into a directory above the state dir only warns
}

@test "session allow file makes that repo writable" {
  echo "$OTHER" > "$USKN_STATE_DIR/sessions/sid12345678/allow"
  run call "git -C $OTHER commit -am x"; [ -z "$output" ]
  run call "cp x $OTHER/"; [ -z "$output" ]
}

@test "two roots: git writes in a cwd worktree of the session repository and copies to the start root are silent" {
  git -C "$ROOT" -c user.name=t -c user.email=t@x commit -q --allow-empty -m init
  WT="$BATS_TEST_TMPDIR/repos/a-wt"; git -C "$ROOT" worktree add -q -b wt "$WT"
  wt() { jq -c -n --arg c "$1" --arg cwd "$WT" '{session_id:"sid12345678", cwd:$cwd, tool_name:"Bash", tool_input:{command:$c}}' | "$SCRIPT"; }
  run wt "git commit -m x"; [ "$status" -eq 0 ]; [ -z "$output" ]
  run wt "cp x.md $ROOT/"; [ -z "$output" ]
  run wt "git -C $OTHER push"; denied
}

@test "cwd moved into another repository: git writes and outside writes there are denied or warned" {
  git -C "$OTHER" init -q -b main
  at() { jq -c -n --arg c "$1" --arg cwd "$OTHER" '{session_id:"sid12345678", cwd:$cwd, tool_name:"Bash", tool_input:{command:$c}}' | "$SCRIPT"; }
  run at "git commit -m x"; [ "$status" -eq 0 ]; denied
  run at "git push origin main"; denied
  run at "echo x > notes.md"; warned
  run at "git log --oneline -3"; [ -z "$output" ]
  run at "cp x.md $ROOT/"; [ -z "$output" ]
}

@test "cwd in a subdirectory of the session root: git writes are silent" {
  mkdir -p "$ROOT/src"
  at() { jq -c -n --arg c "$1" --arg cwd "$ROOT/src" '{session_id:"sid12345678", cwd:$cwd, tool_name:"Bash", tool_input:{command:$c}}' | "$SCRIPT"; }
  run at "git commit -m x"; [ -z "$output" ]
  run at "echo x > ../notes.md"; [ -z "$output" ]
}

@test "broken input: silent exit 0" {
  run bash -c "echo nope | '$SCRIPT'"; [ "$status" -eq 0 ]; [ -z "$output" ]
}

@test "redirects to /dev/null are not outside paths" {
  run call "make verify > /dev/null 2>&1"; [ "$status" -eq 0 ]; [ -z "$output" ]
  run call "cp a.txt /dev/null"; [ -z "$output" ]
}
