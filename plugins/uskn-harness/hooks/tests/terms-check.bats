#!/usr/bin/env bats
# Tests for hooks/scripts/terms-check.sh (spec: terminology-guard).
# The fixture is a small git repo with its own glossary, common-word list and source files.
SCRIPT="$BATS_TEST_DIRNAME/../scripts/terms-check.sh"

setup() {
  export GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@x GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@x
  export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
  R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R/docs" "$R/openspec" "$R/bin"
  export CLAUDE_PROJECT_DIR="$R"
  export USKN_HARNESS_DIR="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  export USKN_COMMON_WORDS="$R/common-words.txt"
  printf 'コマンド\nファイル\n' > "$USKN_COMMON_WORDS"
  cat > "$R/openspec/glossary.yml" <<'YAML'
version: 1
terms:
  - term: "ハーネス"
    definition: "土台。"
    aliases: ["ハーネス基盤"]
    en: "harness"
YAML
  printf '#!/usr/bin/env bash\necho real\n' > "$R/bin/real-script.sh"; chmod +x "$R/bin/real-script.sh"
  printf 'VERIFY_TOKEN=1\n' > "$R/Makefile"
  ( cd "$R" && git init -q -b main && git add -A && git commit -qm init )
}

cli() { "$SCRIPT" "$@"; }
hook() { jq -c -n --arg f "$1" --arg cwd "$R" '{session_id:"s", cwd:$cwd, hook_event_name:"PostToolUse", tool_name:"Write", tool_input:{file_path:$f}, tool_response:{}}' | "$SCRIPT"; }
ctx() { echo "$output" | jq -r '.hookSpecificOutput.additionalContext'; }
# path_without_python: a directory of links to everything on PATH except python3, for a machine without it
path_without_python() {
  local farm="$BATS_TEST_TMPDIR/nopython" d
  mkdir -p "$farm"
  local IFS=:
  for d in $PATH; do [ -d "$d" ] && ln -s "$d"/* "$farm"/ 2>/dev/null; done   # first match wins
  rm -f "$farm"/python3*
  printf '%s' "$farm"
}

@test "a backticked name that exists as a path, a path element, or in a tracked file passes" {
  printf '# t\n\n`bin/real-script.sh` と `Makefile` と `VERIFY_TOKEN` と `docs` を使う。\n' > "$R/docs/ok.md"
  run cli "$R/docs/ok.md"
  [ "$status" -eq 0 ]; [ -z "$output" ]
}

@test "a backticked name that exists nowhere is reported and fails in CLI mode" {
  printf '# t\n\n設定は `harness.yaml` に置く。\n' > "$R/docs/ng.md"
  run cli "$R/docs/ng.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"harness.yaml"* ]]
}

@test "placeholders, assignments and version examples are not names" {
  printf '# t\n\n`<name>` と `KEY=value` と `v26.09.1` と `vYY.MM.X` を書く。\n' > "$R/docs/ph.md"
  run cli "$R/docs/ph.md"
  [ "$status" -eq 0 ]; [ -z "$output" ]
}

@test "the allowlist silences a name that is real but lives outside the repository" {
  printf 'timeout.exe\n' > "$R/openspec/known-names.txt"
  printf '# t\n\nWindowsの `timeout.exe` は別物である。\n' > "$R/docs/ext.md"
  run cli "$R/docs/ext.md"
  [ "$status" -eq 0 ]; [ -z "$output" ]
}

@test "a katakana word that is in neither list is reported; glossary and common words are not" {
  printf '# t\n\nハーネスのコマンドはファイルを読む。\n' > "$R/docs/known.md"
  run cli "$R/docs/known.md"
  [ "$status" -eq 0 ]; [ -z "$output" ]
  printf '# t\n\nこのフレームワークはコマンドを読む。\n' > "$R/docs/new.md"
  run cli "$R/docs/new.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"フレームワーク"* ]]
}

@test "a term listed as an alias is reported with the spelling to use" {
  printf '# t\n\nハーネス基盤を導入する。\n' > "$R/docs/alias.md"
  run cli "$R/docs/alias.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"ハーネス基盤"* ]]; [[ "$output" == *"ハーネス"* ]]
}

@test "quoted terms are checked, code blocks and English files are not" {
  printf '# t\n\n「未知概念」と書く。\n' > "$R/docs/q.md"
  run cli "$R/docs/q.md"
  [ "$status" -ne 0 ]; [[ "$output" == *"未知概念"* ]]
  printf '# t\n\n```\nハーネス基盤 `harness.yaml` 「未知概念」\n```\n' > "$R/docs/fence.md"
  run cli "$R/docs/fence.md"
  [ "$status" -eq 0 ]; [ -z "$output" ]
}

@test "hook mode returns additionalContext and never blocks" {
  printf '# t\n\n設定は `harness.yaml` に置く。\n' > "$R/docs/ng2.md"
  run hook "$R/docs/ng2.md"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "PostToolUse"' >/dev/null
  echo "$output" | jq -e '.decision == null and .hookSpecificOutput.permissionDecision == null' >/dev/null
  ctx | grep -q "harness.yaml"
}

@test "hook mode is silent for a clean file, a non-markdown file, and a missing file" {
  printf '# t\n\n`Makefile` を読む。\n' > "$R/docs/clean.md"
  run hook "$R/docs/clean.md"; [ "$status" -eq 0 ]; [ -z "$output" ]
  # a Japanese comment with an unknown katakana word and a missing name: reported if the file were checked
  printf 'const x = 1; // このフレームワークは `harness.yaml` を読む。日本語のコメントである。\n' > "$R/docs/code.ts"
  run hook "$R/docs/code.ts"; [ "$status" -eq 0 ]; [ -z "$output" ]
  run hook "$R/docs/gone.md"; [ "$status" -eq 0 ]; [ -z "$output" ]
}

@test "hook mode checks .markdown as well as .md" {
  printf '# t\n\n設定は `harness.yaml` に置く。\n' > "$R/docs/ng.markdown"
  run hook "$R/docs/ng.markdown"
  [ "$status" -eq 0 ]
  ctx | grep -q "harness.yaml"
}

@test "a tracked binary or non-UTF-8 file does not stop the check: CLI mode still reports and fails" {
  printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\xff\xfe' > "$R/docs/logo.png"
  printf 'caf\xe9 au lait\n' > "$R/docs/latin1.txt"
  ( cd "$R" && git add -A && git commit -qm binaries )
  printf '# t\n\n設定は `harness.yaml` に置く。\n' > "$R/docs/ng.md"
  run cli "$R/docs/ng.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"harness.yaml"* ]]
}

@test "a crash of the check fails CLI mode and stays silent in hook mode" {
  fb="$BATS_TEST_TMPDIR/fakepy"; mkdir -p "$fb"
  printf '#!/usr/bin/env bash\necho "Traceback (most recent call last): boom" >&2\nexit 1\n' > "$fb/python3"; chmod +x "$fb/python3"
  printf '# t\n\n`Makefile` を読む。\n' > "$R/docs/clean.md"
  PATH="$fb:$PATH" run cli "$R/docs/clean.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Traceback"* ]]
  PATH="$fb:$PATH" run hook "$R/docs/clean.md"
  [ "$status" -eq 0 ]; [ -z "$output" ]
}

@test "without python3: skipped by default, a failure under VERIFY_STRICT=1, silent in hook mode" {
  P="$(path_without_python)"
  printf '# t\n\n設定は `harness.yaml` に置く。\n' > "$R/docs/ng.md"
  PATH="$P" run cli "$R/docs/ng.md"
  [ "$status" -eq 0 ]
  VERIFY_STRICT=1 PATH="$P" run cli "$R/docs/ng.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"VERIFY_STRICT"* ]]
  VERIFY_STRICT=1 PATH="$P" run hook "$R/docs/ng.md"
  [ "$status" -eq 0 ]; [ -z "$output" ]
}

@test "USKN_SKIP_TERMS=1 and a repository without a glossary keep the name check working" {
  printf '# t\n\n設定は `harness.yaml` に置く。ハーネス基盤も書く。\n' > "$R/docs/skip.md"
  USKN_SKIP_TERMS=1 run cli "$R/docs/skip.md"
  [ "$status" -eq 0 ]; [ -z "$output" ]
  rm "$R/openspec/glossary.yml"
  run cli "$R/docs/skip.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"harness.yaml"* ]]; [[ "$output" != *"ハーネス基盤"* ]]
}
