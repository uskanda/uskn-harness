#!/usr/bin/env bash
# Computational sensors for bin/uskn-loop (openspec: loop-criteria). Sourced, not executed. Expects VERIFY_MINUTES
# and with_timeout (from the hooks' lib/common.sh).

# verify_cmd <dir>: the repository's verify convention there (make verify, else pnpm or npm run verify); empty when
# there is none.
verify_cmd() {
  local d="$1" mk
  for mk in Makefile GNUmakefile; do
    if [ -f "$d/$mk" ] && grep -qE '^verify[[:space:]]*:' "$d/$mk"; then echo "make verify"; return; fi
  done
  if [ -f "$d/package.json" ] && jq -e '.scripts.verify' "$d/package.json" >/dev/null 2>&1; then
    if [ -f "$d/pnpm-lock.yaml" ]; then echo "pnpm run verify"; else echo "npm run verify"; fi
  fi
}

# has_verify_at <top> <ref>: whether the tree at <ref> has a verify convention (checked without a checkout).
has_verify_at() {
  local top="$1" ref="$2" mk
  for mk in Makefile GNUmakefile; do
    git -C "$top" show "$ref:$mk" 2>/dev/null | grep -qE '^verify[[:space:]]*:' && return 0
  done
  git -C "$top" show "$ref:package.json" 2>/dev/null | jq -e '.scripts.verify' >/dev/null 2>&1
}

# is_test_path <path>: a test file. openspec/ is documentation, never tests.
is_test_path() {
  case "$1" in openspec/*) return 1 ;; esac
  case "$1" in *test* | *spec* | *__tests__* | *.bats) return 0 ;; esac
  return 1
}

# skip_pattern <path>: the extended regex that marks an added skip in a test file of that kind; empty for others.
skip_pattern() {
  case "$1" in
    *.bats) echo '^[[:space:]]*skip([[:space:]]|$)' ;;
    *.js | *.jsx | *.ts | *.tsx | *.mjs | *.cjs) echo '\.skip\(|(^|[^[:alnum:]_])(xit|xdescribe|xtest)\(' ;;
    *.py) echo '@pytest\.mark\.skip|unittest\.skip' ;;
    *_test.go) echo '(^|[^[:alnum:]_])t\.Skip(f|Now)?\(' ;;
  esac
}

# is_verify_setting <path>: a file that configures the checks (the Makefile, package.json, CI, textlint).
is_verify_setting() {
  case "$1" in
    Makefile | GNUmakefile | package.json | .gitlab-ci.yml | .github/workflows/* | .textlintrc* | */textlintrc.json) return 0 ;;
  esac
  return 1
}

# run_sensors <worktree> <base ref> <change> <out dir>: run every sensor and write <out dir>/sensors.json:
# {failed: [names], blocking_files: [paths], verify_settings: [paths]}. Raw outputs go to <out dir>/<name>.txt.
# Names: uncommitted, verify, openspec, tasks, test-deletion, skip-added.
run_sensors() {
  local wt="$1" base="$2" change="$3" out="$4" cmd tasks p pat file line
  local -a failed=() blocking=() settings=()
  mkdir -p "$out"
  tasks="$wt/openspec/changes/$change/tasks.md"

  git -C "$wt" status --porcelain > "$out/uncommitted.txt"
  [ -s "$out/uncommitted.txt" ] && failed+=(uncommitted)

  cmd="$(verify_cmd "$wt")"
  if [ -z "$cmd" ]; then
    echo "no verify convention" > "$out/verify.txt"; failed+=(verify)
  elif ! (cd "$wt" && with_timeout "$((VERIFY_MINUTES * 60))" bash -c "$cmd") > "$out/verify.txt" 2>&1; then
    failed+=(verify)
  fi

  (cd "$wt" && openspec validate "$change" --strict) > "$out/openspec.txt" 2>&1 || failed+=(openspec)

  if [ ! -f "$tasks" ]; then echo "tasks.md is missing" > "$out/tasks.txt"; failed+=(tasks)
  elif grep -nE '^[[:space:]]*- \[ \]' "$tasks" > "$out/tasks.txt"; then failed+=(tasks); fi

  : > "$out/test-deletion.txt"
  while IFS= read -r p; do
    [ -n "$p" ] && is_test_path "$p" || continue
    grep -qF -- "$p" "$tasks" 2>/dev/null && continue
    echo "$p" >> "$out/test-deletion.txt"; blocking+=("$p")
  done < <(git -C "$wt" diff --name-only --diff-filter=D "$base...HEAD")
  [ -s "$out/test-deletion.txt" ] && failed+=(test-deletion)

  : > "$out/skip-added.txt"
  file=""
  while IFS= read -r line; do
    case "$line" in
      '+++ b/'*) file="${line#+++ b/}"; continue ;;
      '+++ '* | '---'*) continue ;;
      +*) ;;
      *) continue ;;
    esac
    is_test_path "$file" || continue
    pat="$(skip_pattern "$file")"
    [ -n "$pat" ] || continue
    printf '%s\n' "${line#+}" | grep -qE -- "$pat" || continue
    grep -qF -- "$file" "$tasks" 2>/dev/null && continue
    printf '%s: %s\n' "$file" "${line#+}" >> "$out/skip-added.txt"
    blocking+=("$file")
  done < <(git -C "$wt" diff -U0 "$base...HEAD")
  [ -s "$out/skip-added.txt" ] && failed+=(skip-added)

  while IFS= read -r p; do
    [ -n "$p" ] && is_verify_setting "$p" && settings+=("$p")
  done < <(git -C "$wt" diff --name-only "$base...HEAD")

  jq -n --args '$ARGS.positional' ${failed[@]+"${failed[@]}"} > "$out/failed.json"
  jq -n --args '$ARGS.positional | unique' ${blocking[@]+"${blocking[@]}"} > "$out/blocking.json"
  jq -n --args '$ARGS.positional' ${settings[@]+"${settings[@]}"} > "$out/settings.json"
  jq -n --slurpfile f "$out/failed.json" --slurpfile b "$out/blocking.json" --slurpfile s "$out/settings.json" \
    '{failed: $f[0], blocking_files: $b[0], verify_settings: $s[0]}' > "$out/sensors.json"
}
