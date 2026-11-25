#!/usr/bin/env bats
# Tests for hooks/scripts/textlint-check.sh (spec: textlint-hook). textlint is a fake on PATH that logs its
# arguments and cwd, and prints FAKE_FINDINGS (exit 1) when that variable is set.
SCRIPT="$BATS_TEST_DIRNAME/../scripts/textlint-check.sh"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  export USKN_HARNESS_DIR="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  # The hook works in the resolved git top level. TMPDIR can sit behind a symlink (macOS: /var -> /private/var), so the
  # repositories live under the resolved temporary dir, and cwd=... in the log compares equal on every OS.
  TMP="$(cd "$BATS_TEST_TMPDIR" && pwd -P)"
  R="$TMP/repo"; mkdir -p "$R/docs" "$BATS_TEST_TMPDIR/bin"; ( cd "$R" && git init -q -b main )
  export CLAUDE_PROJECT_DIR="$R"
  LOG="$BATS_TEST_TMPDIR/textlint.log"
  cat > "$BATS_TEST_TMPDIR/bin/textlint" <<EOF
#!/usr/bin/env bash
printf 'args=%s\ncwd=%s\n' "\$*" "\$PWD" >> "$LOG"
if [ -n "\${FAKE_FINDINGS:-}" ]; then printf '%s\n' "\$FAKE_FINDINGS"; exit 1; fi
exit 0
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/textlint"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  printf '# 見出し\n\nこれは日本語の文章です。\n' > "$R/docs/ja.md"
  printf '# Title\n\nEnglish only, no Japanese.\n' > "$R/docs/en.md"
  printf 'const x = 1; // 日本語のコメント\n' > "$R/docs/code.ts"
  F1="$R/docs/ja.md: line 3, col 1, Error - Line 3 sentence length(120) exceeds the maximum sentence length of 100. (ja-technical-writing/sentence-length)"
  F2="$R/docs/ja.md: line 5, col 2, Error - 【dict5】 \"確認を行う\"は冗長な表現です。 (ja-technical-writing/ja-no-redundant-expression)"
  F3="$R/docs/ja.md: line 7, col 1, Error - リストアイテムで強調 (@textlint-ja/ai-writing/no-ai-list-formatting)"
}

call() { jq -c -n --arg f "$1" --arg cwd "$R" '{session_id:"s", cwd:$cwd, hook_event_name:"PostToolUse", tool_name:"Write", tool_input:{file_path:$f, content:"x"}, tool_response:{}}' | "$SCRIPT"; }
ctx() { echo "$output" | jq -r '.hookSpecificOutput.additionalContext'; }
# refute <command...>: fails when the command succeeds (a bare `! cmd` mid-test never fails a bats test).
refute() { ! "$@"; }
# path_without <cmd>...: a directory of links to everything on PATH except the named commands (first match wins)
path_without() {
  local farm="$BATS_TEST_TMPDIR/farm" d x
  mkdir -p "$farm"
  local IFS=:
  for d in $PATH; do [ -d "$d" ] && ln -s "$d"/* "$farm"/ 2>/dev/null; done
  for x in "$@"; do rm -f "$farm/$x"; done
  printf '%s' "$farm"
}

@test "japanese markdown with findings returns them as PostToolUse additionalContext" {
  export FAKE_FINDINGS="$F1
$F2
$F3"
  run call "$R/docs/ja.md"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "PostToolUse"' >/dev/null
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == null and .decision == null' >/dev/null
  ctx | grep -q "3 problem"
  ctx | grep -q "docs/ja.md"
  ctx | grep -q "sentence-length"
  ctx | grep -q "no-ai-list-formatting"
  ctx | grep -q "ja-writing"
  grep -q -- "--config $USKN_HARNESS_DIR/skills/ja-writing/textlintrc.json" "$LOG"
  grep -q "$R/docs/ja.md" "$LOG"
}

@test "no findings means no output" {
  run call "$R/docs/ja.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  grep -q "args=" "$LOG"
}

@test "english markdown and non-markdown files are not linted" {
  export FAKE_FINDINGS="$F1"
  run call "$R/docs/en.md"; [ -z "$output" ]
  run call "$R/docs/code.ts"; [ -z "$output" ]
  cp "$R/docs/ja.md" "$R/docs/ja.markdown"   # .md only, as hooks.json's if does
  run call "$R/docs/ja.markdown"; [ -z "$output" ]
  [ ! -e "$LOG" ]
}

@test "an English document that only quotes Japanese is not linted" {
  # skills and AGENTS.md are English by policy; a few Japanese examples must not turn them into Japanese documents.
  { printf '# Skill\n\nEnglish body that keeps going for a while so the ratio stays low. '
    printf 'More English prose here, describing what the skill does and when to use it. '
    printf 'Even more English so the document looks like a real skill document with sections.\n\n'
    printf 'Before: 日本語の例。 After: 直した例。\n'; } > "$R/docs/skill.md"
  export FAKE_FINDINGS="$F1"
  run call "$R/docs/skill.md"
  [ "$status" -eq 0 ]; [ -z "$output" ]
  [ ! -s "$LOG" ]
}

@test "a document that is mostly Japanese is linted even with English in it" {
  { printf '# 見出し\n\n'
    printf 'この文書は日本語で書かれている。英語の識別子 `uskn-harness` や `make verify` を含む。\n'
    printf '検査の対象になることを確かめる。文の数を増やして比率を上げる。日本語の割合が高い文書である。\n'; } > "$R/docs/mixed.md"
  export FAKE_FINDINGS="$F1"
  run call "$R/docs/mixed.md"
  [ "$status" -eq 0 ]
  ctx | grep -q "1 problem"
}

@test "missing file, missing textlint, and USKN_SKIP_TEXTLINT=1 are silent" {
  export FAKE_FINDINGS="$F1"
  run call "$R/docs/nope.md"; [ "$status" -eq 0 ]; [ -z "$output" ]
  run env PATH=/usr/bin:/bin "$SCRIPT" <<<"$(jq -c -n --arg f "$R/docs/ja.md" --arg cwd "$R" '{cwd:$cwd, tool_name:"Write", tool_input:{file_path:$f}}')"
  [ "$status" -eq 0 ]; [ -z "$output" ]
  USKN_SKIP_TEXTLINT=1 run call "$R/docs/ja.md"; [ -z "$output" ]
  [ ! -e "$LOG" ]
}

@test "a repository-local .textlintrc wins and textlint runs from the project root without --config" {
  export FAKE_FINDINGS="$F1"
  echo '{"rules":{}}' > "$R/.textlintrc.json"
  run call "docs/ja.md"
  [ "$status" -eq 0 ]
  ctx | grep -q "1 problem"
  refute grep -q -- "--config" "$LOG"
  grep -q "cwd=$R" "$LOG"
}

@test "the config is looked up at the git root of the file, not at CLAUDE_PROJECT_DIR (a worktree)" {
  export FAKE_FINDINGS="$F1"
  WT="$TMP/wt"; mkdir -p "$WT/docs"; ( cd "$WT" && git init -q -b main )
  echo '{"rules":{}}' > "$WT/.textlintrc.json"
  printf '# 見出し\n\nこれは日本語の文章です。\n' > "$WT/docs/ja.md"
  run bash -c "jq -c -n --arg f '$WT/docs/ja.md' --arg cwd '$WT' '{session_id:\"s\", cwd:\$cwd, tool_name:\"Write\", tool_input:{file_path:\$f}}' | '$SCRIPT'"
  [ "$status" -eq 0 ]
  ctx | grep -q "1 problem"
  refute grep -q -- "--config" "$LOG"
  grep -q "cwd=$WT" "$LOG"
}

@test "findings are capped at 20 lines and the cap is stated" {
  many=""; for i in $(seq 1 30); do many="$many$R/docs/ja.md: line $i, col 1, Error - x (ja-technical-writing/sentence-length)
"; done
  export FAKE_FINDINGS="$many"
  run call "$R/docs/ja.md"
  ctx | grep -q "30 problem"
  [ "$(ctx | grep -c ': line [0-9]*, col')" -le 20 ]
  ctx | grep -q "20"
}

@test "without timeout and gtimeout, a textlint that hangs is cut off and the hook still exits 0" {
  mkdir -p "$BATS_TEST_TMPDIR/slow"
  printf '#!/usr/bin/env bash\nsleep 30\n' > "$BATS_TEST_TMPDIR/slow/textlint"; chmod +x "$BATS_TEST_TMPDIR/slow/textlint"
  P="$(path_without timeout gtimeout)"
  start="$(date +%s)"
  USKN_TEXTLINT_TIMEOUT=1 PATH="$BATS_TEST_TMPDIR/slow:$P" run call "$R/docs/ja.md"
  [ "$status" -eq 0 ]
  [ $(( $(date +%s) - start )) -lt 10 ]
  ctx | grep -q "timed out after 1s"
}

@test "broken stdin or missing file_path exits 0 silently" {
  run bash -c "echo 'not json' | '$SCRIPT'"; [ "$status" -eq 0 ]; [ -z "$output" ]
  run bash -c "printf '{\"tool_name\":\"Write\",\"tool_input\":{}}' | '$SCRIPT'"; [ "$status" -eq 0 ]; [ -z "$output" ]
}

@test "USKN_SKIP_TEXTLINT=1 still reads the whole hook input, so the writer never gets a broken pipe" {
  printf '%*s' 1000000 '' > "$BATS_TEST_TMPDIR/big"
  run bash -c 'set -o pipefail; cat "$1" | USKN_SKIP_TEXTLINT=1 "$2"' _ "$BATS_TEST_TMPDIR/big" "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ---- the git root of the written file (spec: textlint-hook). cwd is repository a; the file may live elsewhere.
call_in() { # <cwd> <file>
  jq -c -n --arg f "$2" --arg cwd "$1" '{session_id:"s", cwd:$cwd, hook_event_name:"PostToolUse", tool_name:"Write", tool_input:{file_path:$f}}' | "$SCRIPT"
}
repo_b() {
  B="$TMP/b"; mkdir -p "$B/docs/legacy"; ( cd "$B" && git init -q -b main )
  printf '# 見出し\n\nこれは日本語の文章です。\n' > "$B/docs/ja.md"
  printf '# 見出し\n\nこれは日本語の文章です。\n' > "$B/docs/legacy/a.md"
}

@test "a document of another repository uses that repository's .textlintrc and runs textlint at its root" {
  export FAKE_FINDINGS="$F1"
  repo_b; echo '{"rules":{}}' > "$B/.textlintrc.json"
  run call_in "$R" "$B/docs/ja.md"
  [ "$status" -eq 0 ]
  ctx | grep -q "1 problem"
  refute grep -q -- "--config" "$LOG"
  grep -qx "cwd=$B" "$LOG"
}

@test "a repository without .textlintrc gets the harness config, with textlint still run at the file's root" {
  repo_b
  run call_in "$R" "$B/docs/ja.md"
  grep -q -- "--config $USKN_HARNESS_DIR/skills/ja-writing/textlintrc.json" "$LOG"
  grep -qx "cwd=$B" "$LOG"
}

@test "the file's root .textlintignore applies: textlint run there leaves the excluded document silent" {
  # The fake honours docs/legacy/** in the .textlintignore of its working directory, as textlint does at the root.
  cat > "$BATS_TEST_TMPDIR/bin/textlint" <<EOF2
#!/usr/bin/env bash
printf 'args=%s\ncwd=%s\n' "\$*" "\$PWD" >> "$LOG"
if [ -f .textlintignore ] && grep -qxF 'docs/legacy/**' .textlintignore; then
  case "\$*" in *"\$PWD/docs/legacy/"*) exit 0 ;; esac
fi
if [ -n "\${FAKE_FINDINGS:-}" ]; then printf '%s\n' "\$FAKE_FINDINGS"; exit 1; fi
exit 0
EOF2
  export FAKE_FINDINGS="$F1"
  repo_b; printf 'docs/legacy/**\n' > "$B/.textlintignore"
  run call_in "$R" "$B/docs/legacy/a.md"
  [ "$status" -eq 0 ]; [ -z "$output" ]
  grep -qx "cwd=$B" "$LOG"
}

@test "a document outside every repository gets the harness config, with textlint run in its directory" {
  export FAKE_FINDINGS="$F1"
  O="$TMP/outside"; mkdir -p "$O"; printf '# 見出し\n\nこれは日本語の文章です。\n' > "$O/x.md"
  echo '{"rules":{}}' > "$R/.textlintrc.json"   # cwd's config must not be picked up for it
  run call_in "$R" "$O/x.md"
  ctx | grep -q "1 problem"
  grep -q -- "--config $USKN_HARNESS_DIR/skills/ja-writing/textlintrc.json" "$LOG"
  grep -qx "cwd=$O" "$LOG"
}

# ---- the confined environment (spec: textlint-hook, confined-hook-sandbox). The plugin is copied into a checkout of
# its own with a confined marker; a fake sandbox-exec logs its arguments and runs the command.
confined_lint() {
  CO="$TMP/checkout"; mkdir -p "$CO/plugins"
  cp -R "$BATS_TEST_DIRNAME/../.." "$CO/plugins/uskn-harness"
  mkdir -p "$CO/skills/ja-writing"; cp "$USKN_HARNESS_DIR/skills/ja-writing/textlintrc.json" "$CO/skills/ja-writing/"
  TOOLS="$TMP/tools"; mkdir -p "$TOOLS/bin" "$HOME/.local/bin"
  printf 'kind=confined\ntools=%s\n' "$TOOLS" > "$CO/.uskn-environment"
  CSCRIPT="$CO/plugins/uskn-harness/hooks/scripts/textlint-check.sh"
  SBLOG="$BATS_TEST_TMPDIR/sandbox-exec.log"; mkdir -p "$BATS_TEST_TMPDIR/sbx"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s"\nwhile [ $# -gt 0 ]; do case "$1" in -f | -D) shift 2 ;; *) break ;; esac; done\nexec "$@"\n' "$SBLOG" > "$BATS_TEST_TMPDIR/sbx/sandbox-exec"
  chmod +x "$BATS_TEST_TMPDIR/sbx/sandbox-exec"
  for w in tools home; do
    printf '#!/usr/bin/env bash\necho "%s $*" >> "%s/which.log"\nprintf "%%s\\n" "$FAKE_FINDINGS"; exit 1\n' "$w" "$BATS_TEST_TMPDIR" > "$BATS_TEST_TMPDIR/tl-$w"
    chmod +x "$BATS_TEST_TMPDIR/tl-$w"
  done
  cp "$BATS_TEST_TMPDIR/tl-tools" "$TOOLS/bin/textlint"; cp "$BATS_TEST_TMPDIR/tl-home" "$HOME/.local/bin/textlint"
  export FAKE_FINDINGS="$F1"
}
ccall() { jq -c -n --arg f "$1" --arg cwd "$R" '{session_id:"s", cwd:$cwd, tool_name:"Write", tool_input:{file_path:$f}}' | "$CSCRIPT"; }

@test "confined on macOS: textlint from the shared tools runs under the rules, never the one in the home" {
  confined_lint
  USKN_HARNESS_OS=Darwin PATH="$BATS_TEST_TMPDIR/sbx:$PATH" run ccall "$R/docs/ja.md"
  [ "$status" -eq 0 ]
  ctx | grep -q "1 problem"
  grep -q "^tools " "$BATS_TEST_TMPDIR/which.log"
  refute grep -q "^home " "$BATS_TEST_TMPDIR/which.log"
  grep -q "confined.sb textlint --config" "$SBLOG"
  grep -q "confined.sb git -C $R/docs rev-parse" "$SBLOG"
}

@test "confined without the rules: textlint does not run, additionalContext says the file was not checked" {
  confined_lint
  USKN_HARNESS_OS=Linux PATH="$BATS_TEST_TMPDIR/sbx:$PATH" run ccall "$R/docs/ja.md"
  [ "$status" -eq 0 ]
  ctx | grep -q "not checked"
  ctx | grep -q "sandbox-exec"
  [ ! -e "$BATS_TEST_TMPDIR/which.log" ]; [ ! -e "$SBLOG" ]
}
