#!/usr/bin/env bash
# allow-repo.sh: let the current session write to a path outside the project root.
#   allow-repo.sh --session <sid8> <path>     append the resolved path to sessions/<session>/allow
#   allow-repo.sh --session <sid8> --list     show what this session allows
# The write-guard and bash-guard hooks read that file. Only the user may ask for this (see the allow-repo skill).
set -u
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
SID8=""; LIST=0; TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --session) SID8="${2:-}"; shift ;;
    --list) LIST=1 ;;
    -h | --help) sed -n '2,6p' "$0"; exit 0 ;;
    *) TARGET="$1" ;;
  esac
  shift
done
[ -n "$SID8" ] || { echo "--session <sid8> is required (see the session: line in <repo-context>)" >&2; exit 2; }
SDIR="$(session_dir_for_prefix "$SID8")" || true
[ -n "${SDIR:-}" ] || { echo "no session state matches $SID8 under $USKN_STATE/sessions" >&2; exit 1; }
if [ "$LIST" = 1 ]; then
  if [ -s "$SDIR/allow" ]; then cat "$SDIR/allow"; else echo "(none)"; fi; exit 0
fi
[ -n "$TARGET" ] || { echo "path is required" >&2; exit 2; }
[ -e "$TARGET" ] || { echo "path does not exist: $TARGET" >&2; exit 1; }
REAL="$(realpath_m "$TARGET")"
grep -qxF "$REAL" "$SDIR/allow" 2>/dev/null || printf '%s\n' "$REAL" >> "$SDIR/allow"
echo "allowed for session $SID8: $REAL"
exit 0
