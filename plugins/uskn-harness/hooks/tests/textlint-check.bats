#!/usr/bin/env bats
# Tests for hooks/scripts/textlint-check.sh (spec: textlint-hook). textlint is a fake on PATH that logs its
# arguments and cwd, and prints FAKE_FINDINGS (exit 1) when that variable is set.
SCRIPT="$BATS_TEST_DIRNAME/../scripts/textlint-check.sh"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  export USKN_HARNESS_DIR="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R/docs" "$BATS_TEST_TMPDIR/bin"; ( cd "$R" && git init -q -b main )
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
  [ "$status" -eq 0 ] && [ -z "$output" ]
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
  ! grep -q -- "--config" "$LOG"
  grep -q "cwd=$R" "$LOG"
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

@test "broken stdin or missing file_path exits 0 silently" {
  run bash -c "echo 'not json' | '$SCRIPT'"; [ "$status" -eq 0 ]; [ -z "$output" ]
  run bash -c "printf '{\"tool_name\":\"Write\",\"tool_input\":{}}' | '$SCRIPT'"; [ "$status" -eq 0 ]; [ -z "$output" ]
}
