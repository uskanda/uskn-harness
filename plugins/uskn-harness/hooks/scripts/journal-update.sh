#!/usr/bin/env bash
# journal-update.sh: the session journal's deterministic part, plus a CLI for the journal skill.
#
#   (stdin JSON)                          Stop hook: create / refresh this session's journal; block once when the
#                                         tree changed and Decisions is still empty (USKN_SKIP_JOURNAL=1 disables the block)
#   --session <sid8> --path               print the journal path
#   --session <sid8> --slug <slug>        rename the journal to <date>-<HHMM>-<slug>.md and set its title
#   --session <sid8> --refresh            refresh the deterministic part without blocking
#
# Journal layout: front matter, "# title", Prompts / Changes / Commits / Skills (regenerated), then
# "<!-- agent -->" followed by Decisions / Open / Next (never touched here).
# Contract (openspec: journal-skeleton): silent unless blocking; exit 0 in hook mode; nothing without ~/.ai-sessions.
set -u
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"

MODE=hook; SID8=""; SLUG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --session) SID8="${2:-}"; shift ;;
    --path) MODE=path ;;
    --slug) MODE=slug; SLUG="${2:-}"; shift ;;
    --refresh) MODE=refresh ;;
    -h | --help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

section_agent() { awk '/^<!-- agent -->/{f=1} f' "$1"; }
decisions_empty() { # true when no non-blank line sits between "## Decisions" and the next heading
  [ -f "$1" ] || return 0
  [ -z "$(awk '/^## Decisions/{f=1; next} f && /^## /{exit} f && NF' "$1")" ]
}

# regenerate <journal> <top> <sdir> <sid> <transcript>
regenerate() {
  local J="$1" TOP="$2" SDIR="$3" SID="$4" TR="$5" title agent prompts skills changes commits bh branch started
  title="$(sed -n 's/^title: //p' "$J" 2>/dev/null | head -n 1)"; [ -n "$title" ] || title="$(sid8 "$SID")"
  if [ -f "$J" ]; then agent="$(section_agent "$J")"; fi
  [ -n "${agent:-}" ] || agent=$'<!-- agent -->\n## Decisions\n\n## Open\n\n## Next\n'
  started="$(cat "$SDIR/started" 2>/dev/null || now_iso)"
  branch="$(git -C "$TOP" branch --show-current 2>/dev/null || true)"
  bh="$(cat "$SDIR/baseline-head" 2>/dev/null || true)"
  if [ -n "$TR" ] && [ -f "$TR" ] && have jq; then
    prompts="$(jq -r '
      select(.type == "user") | .timestamp as $ts
      | (.message.content
         | if type == "string" then .
           elif type == "array" then ([.[] | select(.type == "text") | .text] | join(" "))
           else "" end)
      | gsub("<private>.*?</private>"; "") | gsub("[\\r\\n]+"; " ") | gsub("^\\s+|\\s+$"; "")
      | select(length > 0)
      | select(test("^<(command-|local-command|system-reminder|bash-input|bash-stdout|bash-stderr)") | not)
      | "- \((($ts // "") | .[11:16])) \(.[0:200])"' "$TR" 2>/dev/null || true)"
    skills="$(jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "tool_use" and .name == "Skill") | .input.skill // empty' "$TR" 2>/dev/null | awk '!seen[$0]++' | sed 's/^/- /' || true)"
  else
    prompts="- (transcript not available)"; skills=""
  fi
  if [ -n "$bh" ] && git -C "$TOP" cat-file -e "$bh^{commit}" 2>/dev/null; then
    changes="$(git -C "$TOP" diff --stat "$bh" 2>/dev/null | tail -n 60)"
    commits="$(git -C "$TOP" log --oneline "$bh..HEAD" 2>/dev/null | sed 's/^/- /')"
  else
    changes="$(git -C "$TOP" diff --stat HEAD 2>/dev/null | tail -n 60)"; commits=""
  fi
  local untracked; untracked="$(git -C "$TOP" ls-files --others --exclude-standard 2>/dev/null | head -n 40 | sed 's/^/untracked: /')"
  {
    printf -- '---\nsession: %s\nproject: %s\nrepo: %s\nbranch: %s\nstarted: %s\nupdated: %s\ntitle: %s\n---\n\n# %s\n\n' \
      "$SID" "$(project_key "$TOP")" "$TOP" "$branch" "$started" "$(now_iso)" "$title" "$title"
    printf '## Prompts\n%s\n\n' "${prompts:-- (none)}"
    # shellcheck disable=SC2016  # literal backticks: a markdown code fence
    printf '## Changes\n```\n%s\n%s\n```\n\n' "${changes:-(no changes)}" "$untracked"
    printf '## Commits\n%s\n\n' "${commits:-- (none)}"
    printf '## Skills\n%s\n\n' "${skills:-- (none)}"
    printf '%s\n' "$agent"
  } > "$J.tmp"
  # Only the `updated:` line differs on a quiet refresh: keep the file untouched then, so SessionEnd has nothing to commit.
  if [ -f "$J" ] && [ "$(grep -v '^updated: ' "$J.tmp")" = "$(grep -v '^updated: ' "$J")" ]; then rm -f "$J.tmp"; else mv "$J.tmp" "$J"; fi
}

# ---------------------------------------------------------------- CLI modes
if [ "$MODE" != hook ]; then
  [ -n "$SID8" ] || { echo "--session <sid8> is required" >&2; exit 2; }
  SDIR="$(session_dir_for_prefix "$SID8")" || true
  [ -n "${SDIR:-}" ] || { echo "no session state matches $SID8 under $USKN_STATE/sessions" >&2; exit 1; }
  SID="$(basename "$SDIR")"
  [ -s "$SDIR/journal" ] || { echo "no journal yet for session $SID8 (it appears after the first Stop)" >&2; exit 1; }
  J="$(cat "$SDIR/journal")"
  case "$MODE" in
    path) printf '%s\n' "$J" ;;
    slug)
      [ -n "$SLUG" ] || { echo "--slug needs a value" >&2; exit 2; }
      SLUG="$(printf '%s' "$SLUG" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')"
      base="$(basename "$J")"; prefix="${base:0:16}"   # YYYY-MM-DD-HHMM-
      NEW="$(dirname "$J")/$prefix$SLUG.md"
      if [ "$NEW" != "$J" ]; then mv "$J" "$NEW"; J="$NEW"; printf '%s\n' "$J" > "$SDIR/journal"; fi
      sed -i.bak "s/^title: .*/title: $SLUG/; 0,/^# .*/s//# $SLUG/" "$J" && rm -f "$J.bak"
      printf '%s\n' "$J" ;;
    refresh)
      TOP="$(cat "$SDIR/project" 2>/dev/null || true)"; TR="$(cat "$SDIR/transcript" 2>/dev/null || true)"
      [ -n "$TOP" ] && regenerate "$J" "$TOP" "$SDIR" "$SID" "$TR"; printf '%s\n' "$J" ;;
  esac
  exit 0
fi

# ---------------------------------------------------------------- hook mode
[ -d "$USKN_SESSIONS" ] || exit 0
INPUT="$(cat 2>/dev/null || true)"
[ -z "$(json_field "$INPUT" '.agent_type' agent_type)" ] || exit 0
SID="$(json_field "$INPUT" '.session_id' session_id)"; CWD="$(json_field "$INPUT" '.cwd' cwd)"
TR="$(json_field "$INPUT" '.transcript_path' transcript_path)"; ACTIVE="$(json_bool "$INPUT" stop_hook_active)"
[ -n "$SID" ] || exit 0
TOP="$(git -C "${CWD:-$PWD}" rev-parse --show-toplevel 2>/dev/null || true)"; [ -n "$TOP" ] || exit 0
SDIR="$USKN_STATE/sessions/$SID"; mkdir -p "$SDIR" 2>/dev/null || exit 0
[ -n "$TR" ] && printf '%s\n' "$TR" > "$SDIR/transcript"
[ -s "$SDIR/started" ] || now_iso > "$SDIR/started"
[ -s "$SDIR/project" ] || ( cd "$TOP" && pwd -P ) > "$SDIR/project"
[ -s "$SDIR/baseline-head" ] || git -C "$TOP" rev-parse HEAD > "$SDIR/baseline-head" 2>/dev/null || true
if [ -s "$SDIR/journal" ] && [ -f "$(cat "$SDIR/journal")" ]; then J="$(cat "$SDIR/journal")"
else
  J="$USKN_SESSIONS/$(project_key "$TOP")/$(to_local_stamp "$(cat "$SDIR/started")")-$(sid8 "$SID").md"
  mkdir -p "$(dirname "$J")"; printf '%s\n' "$J" > "$SDIR/journal"
fi
regenerate "$J" "$TOP" "$SDIR" "$SID" "$TR"

[ "${USKN_SKIP_JOURNAL:-0}" = 1 ] && exit 0
[ "$ACTIVE" = true ] && exit 0
[ -f "$SDIR/journal-prompted" ] && exit 0
[ -s "$SDIR/baseline" ] || exit 0
[ "$(tree_fingerprint "$TOP")" = "$(cat "$SDIR/baseline")" ] && exit 0
decisions_empty "$J" || exit 0
: > "$SDIR/journal-prompted"
REASON="uskn-harness journal: this session changed files but its journal has no Decisions yet. Run the journal skill: fill Decisions / Open / Next after the <!-- agent --> marker in $J, then name it with \`journal-update.sh --session $(sid8 "$SID") --slug <kebab-case>\`. Then finish. (This reminder comes once per session; USKN_SKIP_JOURNAL=1 disables it.)"
if have jq; then jq -c -n --arg r "$REASON" '{decision:"block", reason:$r, hookSpecificOutput:{hookEventName:"Stop", decision:"block", reason:$r}}'
else esc="$(printf '%s' "$REASON" | sed 's/\\/\\\\/g; s/"/\\"/g')"; printf '{"decision":"block","reason":"%s","hookSpecificOutput":{"hookEventName":"Stop","decision":"block","reason":"%s"}}\n' "$esc" "$esc"; fi
exit 0
