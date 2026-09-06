#!/usr/bin/env bash
# write-guard.sh: PreToolUse hook (Write | Edit | MultiEdit | NotebookEdit). Denies writes outside the project root
# unless the path is on the fixed allowlist (scratchpad / tmp, ~/.ai-sessions, auto-memory, harness state) or the
# session's allow file (/allow-repo). Silent otherwise. Contract (openspec: write-guard): exit 0 always.
set -u
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
INPUT="$(cat 2>/dev/null || true)"; [ -n "$INPUT" ] || exit 0
FILE="$(json_field "$INPUT" '.tool_input.file_path // .tool_input.notebook_path' file_path)"; [ -n "$FILE" ] || exit 0
CWD="$(json_field "$INPUT" '.cwd' cwd)"; SID="$(json_field "$INPUT" '.session_id' session_id)"
ROOT="$(project_root "${CWD:-$PWD}")"
case "$FILE" in /*) ABS="$FILE" ;; *) ABS="${CWD:-$PWD}/$FILE" ;; esac
ABS="$(realpath_m "$ABS")"
path_allowed "$ABS" "$ROOT" "$SID" && exit 0
deny_json "uskn-harness: writing outside the project root is not allowed. Target: $ABS. Root: $ROOT. Changes another repository needs go through a pull request made from a fresh clone in the scratchpad, whose body carries the handoff. If the user explicitly allowed editing that location in this session, run the allow-repo skill (/allow-repo <path>) first."
exit 0
