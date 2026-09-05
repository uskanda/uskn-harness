#!/usr/bin/env bash
# session-start.sh: repository context for the agent, detected once per session.
#
# Modes
#   session-start.sh                       hook mode: reads {"cwd": ...} on stdin, prints a <repo-context> block
#   session-start.sh [DIR]                 same for DIR, without reading stdin
#   session-start.sh --plain hosting [DIR] prints one word: github | gitlab | unknown
#   session-start.sh --plain branches [DIR] prints default=.. integration=.. qa=.. release_tag=..
#   session-start.sh --json [DIR]          prints one JSON object with everything above
#
# Contract (openspec: session-context-hook, branch-model)
#   - never fails the session: exit 0 whatever happens, print what could be detected
#   - outside a git repository the hook mode prints nothing
#   - branch detection reads local remote-tracking refs only; it never touches the network
#   - AGENTS.md "## Branch model" fenced yaml overrides detected values (qa: none disables qa)
#   - depends on bash, git, awk, sed; uses jq when present, falls back to sed otherwise
set -u

usage() { sed -n '2,15p' "$0"; }

MODE=context
PLAIN=""
DIR=""
SID=""
while [ $# -gt 0 ]; do
  case "$1" in
    --plain) MODE=plain; PLAIN="${2:-}"; shift ;;
    --json) MODE=json ;;
    -h|--help) usage; exit 0 ;;
    *) DIR="$1" ;;
  esac
  shift
done

have() { command -v "$1" >/dev/null 2>&1; }

# Hook mode: the payload carries the session cwd. Prefer it over $PWD.
if [ -z "$DIR" ] && [ "$MODE" = context ] && [ ! -t 0 ]; then
  STDIN="$(cat 2>/dev/null || true)"
  if [ -n "$STDIN" ]; then
    if have jq; then
      DIR="$(printf '%s' "$STDIN" | jq -r '.cwd // empty' 2>/dev/null || true)"
      SID="$(printf '%s' "$STDIN" | jq -r '.session_id // empty' 2>/dev/null || true)"
    else
      DIR="$(printf '%s' "$STDIN" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
      SID="$(printf '%s' "$STDIN" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
    fi
  fi
fi
DIR="${DIR:-$PWD}"

TOP="$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$TOP" ]; then
  case "$MODE" in
    plain) [ "$PLAIN" = hosting ] && echo unknown ;;
    json) printf '{"platform":"unknown","top":""}\n' ;;
  esac
  exit 0
fi

# ---------------------------------------------------------------- hosting
remote_url() {
  local r
  git -C "$TOP" remote get-url origin 2>/dev/null && return 0
  r="$(git -C "$TOP" remote 2>/dev/null | head -n 1)"
  [ -n "$r" ] && git -C "$TOP" remote get-url "$r" 2>/dev/null
  return 0
}

# Host part of a git remote URL: scheme://[user@]host[:port]/path or the scp-like user@host:path.
host_of() {
  local u="$1"
  case "$u" in
    *://*) u="${u#*://}"; u="${u#*@}"; printf '%s' "${u%%[:/]*}" ;;
    *@*:*) u="${u#*@}"; printf '%s' "${u%%:*}" ;;
    *) printf '' ;;
  esac
}

# gh's hosts.yml and glab's config.yml both key entries by host name.
host_in_cli_config() {
  local host="$1" f pat
  pat="^[[:space:]]*${host//./\\.}:"
  for f in "${@:2}"; do
    [ -f "$f" ] && grep -qiE "$pat" "$f" 2>/dev/null && return 0
  done
  return 1
}

URL="$(remote_url)"
HOST="$(host_of "$URL")"
PLATFORM=unknown
REASON=""
case "$HOST" in
  github.com|www.github.com|ssh.github.com) PLATFORM=github; REASON="known host" ;;
  gitlab.com|www.gitlab.com|altssh.gitlab.com) PLATFORM=gitlab; REASON="known host" ;;
  *github*) PLATFORM=github; REASON="host name contains github (assumed GitHub Enterprise)" ;;
  *gitlab*) PLATFORM=gitlab; REASON="host name contains gitlab (assumed self-hosted GitLab)" ;;
esac
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
if [ "$PLATFORM" = unknown ] && [ -n "$HOST" ]; then
  if host_in_cli_config "$HOST" "$XDG/gh/hosts.yml" "$HOME/.config/gh/hosts.yml"; then
    PLATFORM=github; REASON="host registered in gh CLI config"
  elif host_in_cli_config "$HOST" "$XDG/glab-cli/config.yml" "$HOME/.config/glab-cli/config.yml"; then
    PLATFORM=gitlab; REASON="host registered in glab CLI config"
  fi
fi
if [ "$PLATFORM" = unknown ]; then
  if [ -d "$TOP/.github/workflows" ] && [ ! -f "$TOP/.gitlab-ci.yml" ]; then
    PLATFORM=github; REASON="repository has .github/workflows/"
  elif [ -f "$TOP/.gitlab-ci.yml" ] && [ ! -d "$TOP/.github/workflows" ]; then
    PLATFORM=gitlab; REASON="repository has .gitlab-ci.yml"
  fi
fi

# ------------------------------------------------------------ branch model
ref_exists() { git -C "$TOP" show-ref --verify --quiet "$1"; }

DEF=""; DEF_SRC=""
head_ref="$(git -C "$TOP" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)"
if [ -n "$head_ref" ]; then DEF="${head_ref#origin/}"; DEF_SRC="origin/HEAD"
elif ref_exists refs/remotes/origin/main; then DEF=main; DEF_SRC="origin/main exists"
elif ref_exists refs/remotes/origin/master; then DEF=master; DEF_SRC="origin/master exists"
elif ref_exists refs/heads/main; then DEF=main; DEF_SRC="local main exists"
elif ref_exists refs/heads/master; then DEF=master; DEF_SRC="local master exists"
else DEF=main; DEF_SRC="fallback"
fi
if ref_exists refs/remotes/origin/develop; then INT=develop; INT_SRC="origin/develop exists"
else INT="$DEF"; INT_SRC="same as default"
fi
if ref_exists refs/remotes/origin/qa; then QA=qa; QA_SRC="origin/qa exists"
else QA=""; QA_SRC="no origin/qa"
fi
TAG=calver; TAG_SRC="default"

# Overrides: the first fenced block under "## Branch model" in AGENTS.md, key: value per line.
read_overrides() {
  [ -f "$TOP/AGENTS.md" ] || return 0
  awk '
    BEGIN { st = 0 }
    st == 0 && /^##[[:space:]]+[Bb]ranch [Mm]odel[[:space:]]*$/ { st = 1; next }
    st == 1 && /^##[[:space:]]/ { st = 0 }
    st == 1 && /^```/ { st = 2; next }
    st == 2 && /^```/ { exit }
    st == 2 {
      line = $0; sub(/#.*/, "", line)
      if (match(line, /^[[:space:]]*(default|integration|qa|release_tag)[[:space:]]*:[[:space:]]*/)) {
        key = line; sub(/[[:space:]]*:.*/, "", key); gsub(/[[:space:]]/, "", key)
        val = substr(line, RLENGTH + 1); gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
        gsub(/^["'\'']|["'\'']$/, "", val)
        print key "=" val
      }
    }' "$TOP/AGENTS.md" 2>/dev/null || true
}
OVERRIDDEN=0
while IFS='=' read -r k v; do
  [ -n "$k" ] || continue
  OVERRIDDEN=1
  case "$k" in
    default)     [ -n "$v" ] && { DEF="$v"; DEF_SRC="AGENTS.md"; } ;;
    integration) [ -n "$v" ] && { INT="$v"; INT_SRC="AGENTS.md"; } ;;
    qa)          if [ -z "$v" ] || [ "$v" = none ]; then QA=""; QA_SRC="AGENTS.md (none)"; else QA="$v"; QA_SRC="AGENTS.md"; fi ;;
    release_tag) [ -n "$v" ] && { TAG="$v"; TAG_SRC="AGENTS.md"; } ;;
  esac
done < <(read_overrides)

# ------------------------------------------------------------------ output
case "$PLATFORM" in
  github) CLI=gh; TERM_="Pull Request (PR)" ;;
  gitlab) CLI=glab; TERM_="Merge Request (MR)" ;;
  *) CLI=""; TERM_="" ;;
esac

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

case "$MODE" in
  plain)
    case "$PLAIN" in
      hosting) echo "$PLATFORM" ;;
      branches) printf 'default=%s\nintegration=%s\nqa=%s\nrelease_tag=%s\n' "$DEF" "$INT" "$QA" "$TAG" ;;
      *) echo "unknown --plain target: $PLAIN (use hosting or branches)" >&2 ;;
    esac
    ;;
  json)
    if have jq; then
      jq -c -n --arg top "$TOP" --arg remote "$URL" --arg host "$HOST" --arg platform "$PLATFORM" \
        --arg reason "$REASON" --arg cli "$CLI" --arg def "$DEF" --arg def_src "$DEF_SRC" \
        --arg int "$INT" --arg int_src "$INT_SRC" --arg qa "$QA" --arg qa_src "$QA_SRC" \
        --arg tag "$TAG" --arg tag_src "$TAG_SRC" --argjson ov "$OVERRIDDEN" \
        '{top:$top, remote:$remote, host:$host, platform:$platform, hosting_reason:$reason, cli:$cli,
          default:$def, integration:$int, qa:$qa, release_tag:$tag,
          sources:{default:$def_src, integration:$int_src, qa:$qa_src, release_tag:$tag_src},
          agents_md_override:($ov==1)}'
    else
      printf '{"top":"%s","remote":"%s","host":"%s","platform":"%s","hosting_reason":"%s","cli":"%s","default":"%s","integration":"%s","qa":"%s","release_tag":"%s","sources":{"default":"%s","integration":"%s","qa":"%s","release_tag":"%s"},"agents_md_override":%s}\n' \
        "$(json_escape "$TOP")" "$(json_escape "$URL")" "$(json_escape "$HOST")" "$PLATFORM" "$(json_escape "$REASON")" "$CLI" \
        "$(json_escape "$DEF")" "$(json_escape "$INT")" "$(json_escape "$QA")" "$(json_escape "$TAG")" \
        "$(json_escape "$DEF_SRC")" "$(json_escape "$INT_SRC")" "$(json_escape "$QA_SRC")" "$(json_escape "$TAG_SRC")" \
        "$([ "$OVERRIDDEN" = 1 ] && echo true || echo false)"
    fi
    ;;
  context)
    {
      echo "<repo-context>"
      echo "Repository context, detected once at session start. Use these values in skills instead of re-detecting them."
      echo
      echo "- repository: $TOP"
      echo "- remote: ${URL:-(none)}"
      if [ "$PLATFORM" = unknown ]; then
        echo "- platform: unknown"
        echo "  Hosting could not be detected. Skills that need a host CLI must decide from \`git remote -v\` and whether \`gh repo view\` or \`glab repo view\` succeeds."
      else
        echo "- platform: $PLATFORM ($REASON)"
        echo "- cli: $CLI, term: $TERM_"
      fi
      echo "- branch model:"
      echo "  - default: $DEF ($DEF_SRC)"
      echo "  - integration: $INT ($INT_SRC)"
      echo "  - qa: ${QA:-(none)} ($QA_SRC)"
      echo "  - release_tag: $TAG ($TAG_SRC)"
      echo "  Override per repository with a \`## Branch model\` heading in AGENTS.md followed by a yaml block (default / integration / qa / release_tag; \`qa: none\` disables qa)."
      if [ -n "$SID" ]; then
        echo "- session: ${SID:0:8}"
        echo "  Commits made in this session carry the trailer \`Session: ${SID:0:8}\` (the commit skill adds it); \`recall ${SID:0:8}\` finds this session's journal later."
      fi
      echo "</repo-context>"
    }
    ;;
esac
exit 0
