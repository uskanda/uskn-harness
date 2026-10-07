#!/usr/bin/env bash
# State and lock for bin/uskn-loop (openspec: loop-run). Sourced, not executed. Expects USKN_STATE (from the hooks'
# lib/common.sh), HOST_NAME, REPO_PATH, and PR.
#
# state.json: {pr, change, status (running | done | stopped), phase, completed (rounds finished), cost (estimate
# total), comment_id, stop_reason, rounds: [{round, sensors (pass | fail), failed, blocking, findings, question,
# cost, seconds, signature}]}. Raw outputs stay in round-<k>/ next to it.
# shellcheck disable=SC2034  # STATE_DIR and STATE are read by the other files

state_init() {
  STATE_DIR="$USKN_STATE/loop/$HOST_NAME/$REPO_PATH/$PR"
  STATE="$STATE_DIR/state.json"
  mkdir -p "$STATE_DIR"
}

# lock_acquire: take the lock directory; a lock whose process is gone is taken over. Fails while another run lives.
lock_acquire() {
  local pid
  if mkdir "$STATE_DIR/lock" 2>/dev/null; then echo "$$" > "$STATE_DIR/lock/pid"; return 0; fi
  pid="$(cat "$STATE_DIR/lock/pid" 2>/dev/null || true)"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then return 1; fi
  echo "$$" > "$STATE_DIR/lock/pid"
}

lock_release() {
  [ "$(cat "$STATE_DIR/lock/pid" 2>/dev/null || true)" = "$$" ] && rm -rf "$STATE_DIR/lock"
  return 0
}

# state_reset: forget every recorded round (the lock stays).
state_reset() { find "$STATE_DIR" -mindepth 1 -maxdepth 1 ! -name lock -exec rm -rf {} +; }

# state_load <change>: create state.json on the first run; later runs keep it and continue.
state_load() {
  [ -f "$STATE" ] && return 0
  jq -n --argjson n "$PR" --arg c "$1" \
    '{pr: $n, change: $c, status: "running", phase: "", completed: 0, cost: 0, comment_id: null, stop_reason: null,
      rounds: []}' > "$STATE"
}

st() { jq -r "$1" "$STATE"; }

# st_set <jq filter> [jq options]: rewrite state.json through a filter.
st_set() {
  local f="$1"
  shift
  jq "$@" "$f" "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"
}
