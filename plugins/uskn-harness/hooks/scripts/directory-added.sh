#!/usr/bin/env bash
# directory-added.sh: DirectoryAdded hook. When the user adds a directory with /add-dir (or an SDK client with
# register_repo_root), record it in the session's allow file through allow-repo.sh, so that write-guard and
# bash-guard let this session write there; the sandbox already lets Bash write to an added directory (ADR-0010).
# Claude Code does not wait for this hook and it cannot block the add; the systemMessage reaches the next turn.
# Contract (openspec: directory-added-hook): exit 0 always; silent unless it recorded the directory.
set -u
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
INPUT="$(cat 2>/dev/null || true)"; [ -n "$INPUT" ] || exit 0
SID="$(json_field "$INPUT" '.session_id' session_id)"; [ -n "$SID" ] || exit 0
DIR="$(json_field "$INPUT" '.directory' directory)"; [ -n "$DIR" ] && [ -d "$DIR" ] || exit 0
OUT="$("$(dirname "$0")/allow-repo.sh" --session "$SID" "$DIR" 2>/dev/null)" || exit 0
MSG="uskn-harness: ${OUT#allowed for session * }: the user added this directory with /add-dir, so this session may write there (write-guard, bash-guard, and the sandbox)."
if have jq; then jq -c -n --arg m "$MSG" '{systemMessage:$m}'
else printf '{"systemMessage":"%s"}\n' "$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')"; fi
exit 0
