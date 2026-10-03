#!/usr/bin/env bash
# Shared helpers for bin/uskn-loop. Sourced, not executed; expects LOOP_DIR.
# shellcheck disable=SC2034  # the limits are read by the other files of loop/lib

log() { printf 'uskn-loop: %s\n' "$*" >&2; }

# refuse <message>: report and exit 2 (refused). An EXIT trap set by the caller still runs.
refuse() { log "$*"; exit 2; }

# load_limits: set each NAME in loop/limits.env, taking USKN_LOOP_<NAME> when it is set.
load_limits() {
  local line name val ov
  while IFS= read -r line; do
    case "$line" in '' | '#'*) continue ;; esac
    name="${line%%=*}"
    val="${line#*=}"
    ov="USKN_LOOP_$name"
    printf -v "$name" '%s' "${!ov:-$val}"
  done < "$LOOP_DIR/limits.env"
}

# Money and time, with awk: the estimates are decimals.
gt() { awk -v a="$1" -v b="$2" 'BEGIN { exit !(a > b) }'; }
add() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.4f", a + b }'; }
usd() { awk -v a="$1" 'BEGIN { printf "$%.2f", a }'; }
now() { date +%s; }

# tail_of <file> [lines]: the last lines of a file, for a prompt (never for a comment).
tail_of() { [ -f "$1" ] && tail -n "${2:-30}" "$1"; }
