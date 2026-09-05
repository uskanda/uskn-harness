#!/usr/bin/env bash
# textlint-check.sh: PostToolUse hook (Write | Edit | MultiEdit). When the written file is Markdown written in
# Japanese (kana at or above a share of the file), run textlint on it and return the findings as additionalContext. This is the
# sensor for the ja-writing skill. Config: the repository's own .textlintrc* when present, else
# skills/ja-writing/textlintrc.json in the harness checkout.
# Contract (openspec: textlint-hook): never blocks; exit 0 always; silent unless textlint reports problems;
# nothing when textlint is missing, the file is not Japanese Markdown, or USKN_SKIP_TEXTLINT=1.
set -u
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
[ "${USKN_SKIP_TEXTLINT:-0}" = 1 ] && exit 0
INPUT="$(cat 2>/dev/null || true)"; [ -n "$INPUT" ] || exit 0
FILE="$(json_field "$INPUT" '.tool_input.file_path' file_path)"; [ -n "$FILE" ] || exit 0
case "$FILE" in *.md | *.markdown) ;; *) exit 0 ;; esac
CWD="$(json_field "$INPUT" '.cwd' cwd)"
case "$FILE" in /*) ABS="$FILE" ;; *) ABS="${CWD:-$PWD}/$FILE" ;; esac
ABS="$(realpath_m "$ABS")"
[ -f "$ABS" ] || exit 0
# Japanese enough to lint? Kana bytes as a share of the file. A skill or an AGENTS.md quotes Japanese examples
# (2% and under here) but is English by policy; a Japanese document runs 11% and up. USKN_TEXTLINT_MIN_JA overrides.
KANA="$(LC_ALL=C grep -oE $'\xe3[\x81\x82\x83].' "$ABS" 2>/dev/null | wc -l)"
BYTES="$(wc -c < "$ABS" 2>/dev/null || echo 0)"
[ "$BYTES" -gt 0 ] || exit 0
[ $((KANA * 100 / BYTES)) -ge "${USKN_TEXTLINT_MIN_JA:-6}" ] || exit 0
have textlint || exit 0
ROOT="$(project_root "${CWD:-$PWD}")"
CONF=""
if ! ls "$ROOT"/.textlintrc "$ROOT"/.textlintrc.* >/dev/null 2>&1; then
  CONF="$(harness_dir)/skills/ja-writing/textlintrc.json"; [ -f "$CONF" ] || exit 0
fi
MAX=20
if have timeout; then OUT="$(cd "$ROOT" && timeout 25 textlint ${CONF:+--config "$CONF"} --format compact "$ABS" 2>&1)"; RC=$?
else OUT="$(cd "$ROOT" && textlint ${CONF:+--config "$CONF"} --format compact "$ABS" 2>&1)"; RC=$?; fi
[ "$RC" -ne 0 ] || exit 0
REL="${ABS#"$ROOT"/}"
FINDINGS="$(printf '%s\n' "$OUT" | grep -E ': line [0-9]+, col [0-9]+,' | sed "s#^$ABS#$REL#")"
N="$(printf '%s\n' "$FINDINGS" | grep -c .)"
if [ "$N" -eq 0 ]; then
  MSG="uskn-harness textlint: could not lint $REL (exit $RC): $(printf '%s\n' "$OUT" | head -n 5). If textlint or its presets are missing, run uskn-harness doctor."
else
  CAP=""; [ "$N" -gt "$MAX" ] && CAP=" (showing the first $MAX)"
  MSG="uskn-harness textlint: $N problem(s) in $REL$CAP. Fix them before finishing; the rules and the fixes are in the ja-writing skill. Re-run: textlint ${CONF:+--config $CONF }--format compact $REL
$(printf '%s\n' "$FINDINGS" | head -n "$MAX")"
fi
if have jq; then jq -c -n --arg m "$MSG" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
else printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}')"; fi
exit 0
