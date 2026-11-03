#!/usr/bin/env bash
# archive-check.sh: list the OpenSpec changes a branch touched and left unarchived (openspec: claude-plugin-packaging;
# ADR-0014). bash-guard runs it before an integrating operation, `make verify-archive` in CI, and the pr and push
# skills through bin/uskn-archive-check.
#   archive-check.sh --base <ref> [DIR]
# A change is openspec/changes/<name>/ (openspec/changes/archive/ does not count). It is listed when the diff from
# the merge-base of <ref> and HEAD to HEAD touches it, HEAD still has it, and HEAD has no
# openspec/changes/<name>/.archive-later (the archive-later declaration). Only HEAD's tree counts: pushes and merges
# carry commits, not the working tree. Git only: no OpenSpec CLI, no network.
# Output: one name per line, sorted. Exit 1 with names, 0 without, 2 when it cannot decide (reason on stderr).
set -u
BASE=""; DIR="."
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:-}"; shift ;;
    --base=*) BASE="${1#--base=}" ;;
    -h | --help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "archive-check: unknown option $1" >&2; exit 2 ;;
    *) DIR="$1" ;;
  esac
  shift
done
[ -n "$BASE" ] || { echo "archive-check: --base <ref> is required" >&2; exit 2; }
cd "$DIR" 2>/dev/null || { echo "archive-check: no such directory: $DIR" >&2; exit 2; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "archive-check: not a git work tree: $DIR" >&2; exit 2; }
git rev-parse -q --verify "$BASE^{commit}" >/dev/null 2>&1 || { echo "archive-check: no such ref: $BASE" >&2; exit 2; }
MB="$(git merge-base "$BASE" HEAD 2>/dev/null)" || { echo "archive-check: no merge-base of $BASE and HEAD" >&2; exit 2; }
TOP="$(git rev-parse --show-toplevel)"; cd "$TOP" || exit 2
CHANGED="$(git diff --name-only "$MB" HEAD -- openspec/changes/ 2>/dev/null)" || { echo "archive-check: git diff failed" >&2; exit 2; }
FOUND="$(printf '%s\n' "$CHANGED" | sed -n -E 's#^openspec/changes/([^/]+)/.+#\1#p' | grep -vx archive | sort -u | while IFS= read -r name; do
  [ -n "$name" ] || continue
  [ "$(git cat-file -t "HEAD:openspec/changes/$name" 2>/dev/null)" = tree ] || continue
  git cat-file -e "HEAD:openspec/changes/$name/.archive-later" 2>/dev/null && continue
  printf '%s\n' "$name"
done)"
[ -n "$FOUND" ] || exit 0
printf '%s\n' "$FOUND"
exit 1
