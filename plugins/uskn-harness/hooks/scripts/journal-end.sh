#!/usr/bin/env bash
# journal-end.sh: SessionEnd hook (timeout 60). Refresh this session's journal once more, then commit it in
# ~/.ai-sessions and try to push. Push failures are ignored (retried at the next session end).
# Contract (openspec: journal-sync): silent; exit 0 always.
set -u
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
INPUT="$(cat 2>/dev/null || true)"
[ -z "$(json_field "$INPUT" '.agent_type' agent_type)" ] || exit 0
[ -d "$USKN_SESSIONS/.git" ] || exit 0
SID="$(json_field "$INPUT" '.session_id' session_id)"
printf '%s' "$INPUT" | USKN_SKIP_JOURNAL=1 "$(dirname "$0")/journal-update.sh" >/dev/null 2>&1 || true
cd "$USKN_SESSIONS" || exit 0
git add -A >/dev/null 2>&1 || exit 0
git diff --cached --quiet && exit 0
MSG="journal"
if [ -n "$SID" ] && [ -s "$USKN_STATE/sessions/$SID/journal" ]; then
  J="$(cat "$USKN_STATE/sessions/$SID/journal")"
  MSG="$(sed -n 's/^project: //p' "$J" 2>/dev/null | head -n 1): $(sed -n 's/^title: //p' "$J" 2>/dev/null | head -n 1)"
fi
git -c user.name="${GIT_AUTHOR_NAME:-uskn-harness}" -c user.email="${GIT_AUTHOR_EMAIL:-uskn-harness@local}" commit -q -m "$MSG" >/dev/null 2>&1 || exit 0
t() { if have timeout; then timeout 20 "$@"; else "$@"; fi; }
t git push -q origin HEAD >/dev/null 2>&1 || { t git pull -q --rebase >/dev/null 2>&1 && t git push -q origin HEAD >/dev/null 2>&1; } || true
exit 0
