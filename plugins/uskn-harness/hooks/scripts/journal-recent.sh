#!/usr/bin/env bash
# journal-recent.sh: SessionStart hook. Injects title / Decisions / Next of the three most recent journals of this
# project as a <recent-sessions> block. Silent when there are none. Exit 0 always.
set -u
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
INPUT="$(cat 2>/dev/null || true)"
SID="$(json_field "$INPUT" '.session_id' session_id)"; CWD="$(json_field "$INPUT" '.cwd' cwd)"
TOP="$(git -C "${CWD:-$PWD}" rev-parse --show-toplevel 2>/dev/null || true)"; [ -n "$TOP" ] || exit 0
DIR="$USKN_SESSIONS/$(project_key "$TOP")"; [ -d "$DIR" ] || exit 0
section() { awk -v h="$2" -v max=10 '$0 == h {f=1; next} f && /^## /{exit} f && NF {print; if (++n >= max) exit}' "$1"; }
OUT=""; COUNT=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ -n "$SID" ] && grep -q "^session: $SID$" "$f" 2>/dev/null; then continue; fi
  title="$(sed -n 's/^title: //p' "$f" | head -n 1)"; [ -n "$title" ] || title="$(basename "$f" .md)"
  OUT="$OUT
### $(basename "$f" .md): $title
Decisions:
$(section "$f" '## Decisions' | sed 's/^/  /')
Next:
$(section "$f" '## Next' | sed 's/^/  /')"
  COUNT=$((COUNT + 1)); [ "$COUNT" -ge 3 ] && break
done < <(find "$DIR" -maxdepth 1 -name '*.md' 2>/dev/null | sort -r)
[ "$COUNT" -gt 0 ] || exit 0
printf '<recent-sessions>\nThe %d most recent journals of this project (%s). Use recall <keywords|sid8> for more.\n%s\n</recent-sessions>\n' "$COUNT" "$DIR" "$OUT"
exit 0
