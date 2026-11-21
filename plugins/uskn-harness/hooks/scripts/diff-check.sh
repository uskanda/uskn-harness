#!/usr/bin/env bash
# diff-check.sh: removed tests, added skip markers, and changed verify settings in a branch (openspec: diff-check;
# ADR-0015). The verify and audit skills run it through bin/uskn-diff-check before a claim that work is done.
#   diff-check.sh --base <ref> [--allow-from <file>]... [DIR]
# The diff runs from the merge-base of <ref> and HEAD to the working tree of DIR (default: the current directory), so
# committed changes and uncommitted changes to tracked files both count; untracked files are not read.
# Output, one finding per line:
#   test-deleted <path>          a test file the diff removes
#   skip-added <path>: <line>    a line the diff adds to a test file that marks a test skipped
#   verify-setting <path>        a file that configures the checks (Makefile, package.json, CI, textlint)
# A path that appears as text in an --allow-from file (a change's tasks.md) is left out of test-deleted and
# skip-added. Exit 1 when a test-deleted or skip-added line was printed, 0 otherwise, 2 when it cannot decide (reason
# on stderr). Git only. The three predicates came from the retired loop runner's sensors and keep its judgement.
set -u
BASE=""; DIR="."; ALLOW=()
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:-}"; shift ;;
    --base=*) BASE="${1#--base=}" ;;
    --allow-from) ALLOW+=("${2:-}"); shift ;;
    --allow-from=*) ALLOW+=("${1#--allow-from=}") ;;
    -h | --help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "diff-check: unknown option $1" >&2; exit 2 ;;
    *) DIR="$1" ;;
  esac
  shift
done
[ -n "$BASE" ] || { echo "diff-check: --base <ref> is required" >&2; exit 2; }
for f in ${ALLOW[@]+"${ALLOW[@]}"}; do
  [ -f "$f" ] || { echo "diff-check: no such --allow-from file: $f" >&2; exit 2; }
done
cd "$DIR" 2>/dev/null || { echo "diff-check: no such directory: $DIR" >&2; exit 2; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "diff-check: not a git work tree: $DIR" >&2; exit 2; }
git rev-parse -q --verify "$BASE^{commit}" >/dev/null 2>&1 || { echo "diff-check: no such ref: $BASE" >&2; exit 2; }
MB="$(git merge-base "$BASE" HEAD 2>/dev/null)" || { echo "diff-check: no merge-base of $BASE and HEAD" >&2; exit 2; }
TOP="$(git rev-parse --show-toplevel)"; cd "$TOP" || exit 2

# is_test_path <path>: a test file. openspec/ is documentation, never tests. *test* also covers __tests__/.
is_test_path() {
  case "$1" in openspec/*) return 1 ;; esac
  case "$1" in *test* | *spec* | *.bats) return 0 ;; esac
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
# is_verify_setting <path>: a file that configures the checks.
is_verify_setting() {
  case "$1" in
    Makefile | GNUmakefile | package.json | .gitlab-ci.yml | .github/workflows/* | .textlintrc* | */textlintrc.json) return 0 ;;
  esac
  return 1
}
# allowed <path>: an --allow-from file names the path.
allowed() {
  local f
  for f in ${ALLOW[@]+"${ALLOW[@]}"}; do grep -qF -- "$1" "$f" && return 0; done
  return 1
}

GIT=(git -c core.quotePath=false)
DELETED="$("${GIT[@]}" diff --name-only --diff-filter=D "$MB" --)" || { echo "diff-check: git diff failed" >&2; exit 2; }
PATCH="$("${GIT[@]}" diff -U0 --no-color "$MB" --)" || { echo "diff-check: git diff failed" >&2; exit 2; }
CHANGED="$("${GIT[@]}" diff --name-only "$MB" --)" || { echo "diff-check: git diff failed" >&2; exit 2; }

rc=0
while IFS= read -r p; do
  if [ -z "$p" ] || ! is_test_path "$p" || allowed "$p"; then continue; fi
  printf 'test-deleted %s\n' "$p"; rc=1
done <<<"$DELETED"

file=""
while IFS= read -r line; do
  case "$line" in
    '+++ b/'*) file="${line#+++ b/}"; continue ;;
    '+++ '* | '---'*) continue ;;
    +*) ;;
    *) continue ;;
  esac
  if [ -z "$file" ] || ! is_test_path "$file"; then continue; fi
  pat="$(skip_pattern "$file")"
  [ -n "$pat" ] || continue
  printf '%s\n' "${line#+}" | grep -qE -- "$pat" || continue
  allowed "$file" && continue
  printf 'skip-added %s: %s\n' "$file" "$(printf '%s' "${line#+}" | sed -E 's/^[[:space:]]+//')"; rc=1
done <<<"$PATCH"

while IFS= read -r p; do
  [ -n "$p" ] && is_verify_setting "$p" && printf 'verify-setting %s\n' "$p"
done <<<"$CHANGED"
exit "$rc"
