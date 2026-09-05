#!/usr/bin/env bash
# session-baseline.sh: SessionStart hook. Records the working tree fingerprint at session start so later
# hooks (verify gate, journal) can tell what this session changed. Silent; exit 0 always.
# State: ${XDG_STATE_HOME:-~/.local/state}/uskn-harness/sessions/<session_id>/{baseline,project,started}
set -u
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
INPUT="$(cat 2>/dev/null || true)"
SID="$(json_field "$INPUT" '.session_id' session_id)"; CWD="$(json_field "$INPUT" '.cwd' cwd)"
[ -n "$SID" ] || exit 0
TOP="$(git -C "${CWD:-$PWD}" rev-parse --show-toplevel 2>/dev/null || true)"; [ -n "$TOP" ] || exit 0
DIR="$USKN_STATE/sessions/$SID"; mkdir -p "$DIR" 2>/dev/null || exit 0
[ -s "$DIR/baseline" ] && exit 0
tree_fingerprint "$TOP" > "$DIR/baseline"
( cd "$TOP" && pwd -P ) > "$DIR/project"
now_iso > "$DIR/started"
exit 0
