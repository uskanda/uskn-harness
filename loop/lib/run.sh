#!/usr/bin/env bash
# The loop of bin/uskn-loop (openspec: loop-run, loop-criteria). Sourced, not executed. Expects the other files of
# loop/lib, the hooks' lib/common.sh, LOOP_DIR, and usage.
# shellcheck disable=SC2034  # ME and the globals set here are read by the other files

# pr_number <ref>: the number in 12, #12, !12, .../pull/12, or .../merge_requests/12.
pr_number() {
  local r="${1#[#!]}"
  case "$r" in
    '' | *[!0-9]*) r="$(printf '%s' "$1" | sed -nE 's#.*/(pull|merge_requests)/([0-9]+)([/?#].*)?$#\2#p')" ;;
  esac
  [ -n "$r" ] && [ "$r" -gt 0 ] 2>/dev/null && echo "$r"
}

loop_run() {
  local ref="" reset=0 a
  for a in "$@"; do
    case "$a" in
      --reset) reset=1 ;;
      -*) usage; return 2 ;;
      *) if [ -z "$ref" ]; then ref="$a"; else usage; return 2; fi ;;
    esac
  done
  [ -n "$ref" ] || { usage; return 2; }
  main_top || refuse "not inside a git clone: run uskn-loop inside the clone of the PR's repository"
  host_detect "$TOP" || refuse "origin is neither a GitHub nor a GitLab repository"
  PR="$(pr_number "$ref")" || refuse "not a PR or MR number or URL: $ref"
  load_limits
  state_init
  lock_acquire || refuse "a loop for #$PR is already running (lock: $STATE_DIR/lock)"
  trap lock_release EXIT
  [ "$reset" = 0 ] || state_reset
  accept
  state_load "$CHANGE"
  st_set '.status = "running" | .stop_reason = null'
  if ! worktree_prepare; then finish_stop conflict; return 3; fi
  rounds
}

# main_top: set TOP to the clone's main working tree, also when run from inside one of its worktrees.
main_top() {
  local common
  TOP="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  common="$(git -C "$TOP" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 0
  case "$common" in */.git) TOP="${common%/.git}" ;; esac
}

# accept: check the four conditions and the verify convention, set ME, HEAD_BR, BASE_BR, and CHANGE; exit 2 with
# every unmet condition listed otherwise. Nothing is created before it passes.
accept() {
  local pr changes n f
  local -a reasons=() missing=()
  pr="$(host_pr "$PR")"
  [ -n "$pr" ] || refuse "cannot read #$PR from $HOST_KIND"
  ME="$(host_user)"
  [ -n "$ME" ] || refuse "cannot tell which $HOST_KIND user is signed in"
  HEAD_BR="$(jq -r .head <<< "$pr")"
  BASE_BR="$(jq -r .base <<< "$pr")"
  [ "$(jq -r .state <<< "$pr")" = open ] || reasons+=("it is not open (state: $(jq -r .state <<< "$pr"))")
  [ "$(jq -r .fork <<< "$pr")" = false ] || reasons+=("its head branch is in a fork")
  [ "$(jq -r .author <<< "$pr")" = "$ME" ] || reasons+=("its author is $(jq -r .author <<< "$pr"), not $ME")
  if ! git -C "$TOP" fetch -q origin "$BASE_BR" "$HEAD_BR" 2>/dev/null; then
    reasons+=("cannot fetch $BASE_BR and $HEAD_BR from origin")
  else
    changes="$(git -C "$TOP" diff --name-only --diff-filter=A "origin/$BASE_BR...origin/$HEAD_BR" -- openspec/changes |
      sed -n 's#^openspec/changes/\([^/]*\)/.*#\1#p' | grep -vx archive | sort -u)"
    n="$(printf '%s\n' "$changes" | grep -c . || true)"
    case "$n" in
      0) reasons+=("it adds no OpenSpec change under openspec/changes/") ;;
      1)
        CHANGE="$changes"
        for f in grilling.md proposal.md tasks.md; do
          git -C "$TOP" cat-file -e "origin/$HEAD_BR:openspec/changes/$CHANGE/$f" 2>/dev/null || missing+=("$f")
        done
        git -C "$TOP" ls-tree -r --name-only "origin/$HEAD_BR" -- "openspec/changes/$CHANGE/specs" | grep -q '/spec\.md$' ||
          git -C "$TOP" show "origin/$HEAD_BR:openspec/changes/$CHANGE/.openspec.yaml" 2>/dev/null |
          grep -qE '^skip_specs:[[:space:]]*true' || missing+=("specs")
        [ ${#missing[@]} -eq 0 ] || reasons+=("the change $CHANGE lacks: ${missing[*]}") ;;
      *) reasons+=("it adds $n changes: $(printf '%s\n' "$changes" | paste -sd, - | sed 's/,/, /g')") ;;
    esac
    has_verify_at "$TOP" "origin/$HEAD_BR" ||
      reasons+=("the repository has no verify convention (make verify, pnpm run verify, or npm run verify)")
  fi
  if [ ${#reasons[@]} -gt 0 ]; then
    log "#$PR is not accepted:"
    printf '  - %s\n' "${reasons[@]}" >&2
    exit 2
  fi
}

# worktree_prepare: create .claude/worktrees/loop-pr-<n> from origin/<head> on the local branch loop/pr-<n>, or reuse
# it and fast-forward it to origin/<head>. Fails when the two diverged.
worktree_prepare() {
  local ex counts ahead behind
  WT="$TOP/.claude/worktrees/loop-pr-$PR"
  if ! git -C "$TOP" check-ignore -q ".claude/worktrees/loop-pr-$PR"; then
    ex="$(git -C "$TOP" rev-parse --path-format=absolute --git-path info/exclude)"
    mkdir -p "$(dirname "$ex")"
    printf '.claude/worktrees/\n' >> "$ex"
  fi
  git -C "$TOP" worktree prune
  if git -C "$WT" rev-parse --git-dir >/dev/null 2>&1; then
    counts="$(git -C "$WT" rev-list --left-right --count "HEAD...origin/$HEAD_BR")" || return 1
    ahead="${counts%%[[:space:]]*}"
    behind="${counts##*[[:space:]]}"
    [ "$behind" -eq 0 ] && return 0
    if [ "$ahead" -ne 0 ]; then log "the worktree and origin/$HEAD_BR diverged"; return 1; fi
    git -C "$WT" merge -q --ff-only "origin/$HEAD_BR"
  else
    mkdir -p "$(dirname "$WT")"
    git -C "$TOP" worktree add -q -B "loop/pr-$PR" "$WT" "origin/$HEAD_BR"
  fi
}

rounds() {
  local k rd t0
  while :; do
    k=$(($(st .completed) + 1))
    if [ "$k" -gt "$ROUNDS" ]; then finish_stop rounds; return 3; fi
    if gt "$(st .cost)" "$PR_BUDGET_USD"; then finish_stop budget; return 3; fi
    if host_pr "$PR" | jq -e '.conflict' >/dev/null; then finish_stop conflict; return 3; fi
    rd="$STATE_DIR/round-$k"
    rm -rf "$rd"
    mkdir -p "$rd"
    t0="$(now)"
    ROUND_COST=0
    comment_progress 実装中
    run_implementer "$k" "$rd"
    if ! push_head "$rd"; then finish_stop push; return 3; fi
    comment_progress 検証中
    run_sensors "$WT" "origin/$BASE_BR" "$CHANGE" "$rd"
    if [ "$(jq '.failed | length' "$rd/sensors.json")" -gt 0 ]; then
      record_round "$k" "$rd" "$t0"
      if no_progress; then finish_stop no-progress; return 3; fi
      continue
    fi
    comment_progress 監査中
    run_auditor "$rd"
    record_round "$k" "$rd" "$t0"
    if [ ! -s "$rd/verdict.json" ]; then finish_stop no-verdict; return 3; fi
    if [ -n "$(jq -r '.question' "$rd/verdict.json")" ]; then finish_stop question; return 3; fi
    if [ "$(jq -r "$COMPLETE" "$rd/verdict.json")" = true ]; then finish_done; return 0; fi
    if no_progress; then finish_stop no-progress; return 3; fi
  done
}

# The auditor's part of the completion criteria: a pass, no blocking finding, and every scenario tested and passing.
COMPLETE='(.verdict == "pass") and ([.findings[] | select(.severity == "blocking")] | length == 0)
  and (.scenarios | length > 0) and all(.scenarios[]; (.tests | length > 0) and .status == "pass")'

# spend <claude json>: add its total_cost_usd to the round and to the PR's total.
spend() {
  local c
  c="$(jq -r '.total_cost_usd // 0' "$1" 2>/dev/null || echo 0)"
  [ -n "$c" ] || c=0
  ROUND_COST="$(add "$ROUND_COST" "$c")"
  st_set '.cost = (.cost + $c)' --argjson c "$c"
}

run_implementer() {
  local k="$1" rd="$2"
  impl_prompt "$k" > "$rd/implementer.prompt"
  (cd "$WT" && with_timeout "$((IMPL_MINUTES * 60))" claude -p "$(cat "$rd/implementer.prompt")" \
    --permission-mode auto --permission-prompts none --max-budget-usd "$IMPL_BUDGET_USD" --output-format json \
    --append-system-prompt-file "$LOOP_DIR/prompts/implementer.md") > "$rd/implementer.json" 2> "$rd/implementer.err" ||
    log "the implementer exited with status $? in round $k"
  spend "$rd/implementer.json"
}

# impl_prompt <round>: /opsx:apply in round 1; later, the previous round's failed sensors and blocking findings.
impl_prompt() {
  local k="$1" prev name
  if [ "$k" -eq 1 ]; then echo "/opsx:apply $CHANGE"; return; fi
  prev="$STATE_DIR/round-$((k - 1))"
  echo "Continue the change $CHANGE (openspec/changes/$CHANGE/) with the opsx:apply skill."
  echo "The previous round of uskn-loop left the problems below. Fix them first, then finish the open tasks."
  if [ "$(jq '.failed | length' "$prev/sensors.json" 2>/dev/null || echo 0)" -gt 0 ]; then
    echo
    echo "## Failed checks"
    for name in $(jq -r '.failed[]' "$prev/sensors.json"); do
      echo
      echo "### $name"
      echo
      echo '```text'
      tail_of "$prev/$name.txt" 40
      echo '```'
    done
  fi
  if [ -s "$prev/verdict.json" ] && [ "$(jq '[.findings[] | select(.severity == "blocking")] | length' "$prev/verdict.json")" -gt 0 ]; then
    echo
    echo "## Blocking findings from the auditor"
    echo
    jq -r '.findings[] | select(.severity == "blocking") | "- `\(.file):\(.line)` \(.summary) (evidence: \(.evidence))"' "$prev/verdict.json"
  fi
  if [ -s "$prev/verdict.json" ] && [ "$(jq '[.scenarios[] | select(.status != "pass" or (.tests | length == 0))] | length' "$prev/verdict.json")" -gt 0 ]; then
    echo
    echo "## Scenarios the auditor could not confirm"
    echo
    jq -r '.scenarios[] | select(.status != "pass" or (.tests | length == 0)) | "- \(.scenario)"' "$prev/verdict.json"
  fi
}

# push_head <round dir>: push the worktree's new commits to the PR's head branch (and nowhere else).
push_head() {
  local n
  n="$(git -C "$WT" rev-list --count "origin/$HEAD_BR..HEAD" 2>/dev/null || echo 0)"
  [ "$n" -gt 0 ] || return 0
  git -C "$WT" push -q origin "HEAD:refs/heads/$HEAD_BR" 2> "$1/push.txt"
}

# run_auditor <round dir>: the auditor in the same worktree, read-only tools; the worktree is put back afterwards.
# Writes verdict.json only when structured_output carries all four fields.
run_auditor() {
  local rd="$1" head
  head="$(git -C "$WT" rev-parse HEAD)"
  audit_prompt "$rd" > "$rd/auditor.prompt"
  (cd "$WT" && with_timeout "$((AUDIT_MINUTES * 60))" claude -p "$(cat "$rd/auditor.prompt")" \
    --model opus --effort high --tools Read,Grep,Glob,Bash --disallowedTools Edit,Write,NotebookEdit \
    --strict-mcp-config --permission-mode auto --permission-prompts none --max-budget-usd "$AUDIT_BUDGET_USD" \
    --json-schema "$(cat "$LOOP_DIR/verdict.schema.json")" --output-format json \
    --append-system-prompt-file "$LOOP_DIR/prompts/auditor.md") > "$rd/auditor.json" 2> "$rd/auditor.err" ||
    log "the auditor exited with status $?"
  git -C "$WT" reset -q --hard "$head"
  git -C "$WT" clean -qfd
  spend "$rd/auditor.json"
  jq -c '.structured_output
    | select(type == "object" and (.verdict == "pass" or .verdict == "fail") and (.scenarios | type) == "array"
             and (.findings | type) == "array" and (.question | type) == "string")' \
    "$rd/auditor.json" > "$rd/verdict.json" 2>/dev/null || : > "$rd/verdict.json"
}

audit_prompt() {
  local rd="$1" prev
  echo "Audit the change $CHANGE in the current directory, a worktree of its spec PR."
  echo "Its artifacts are in openspec/changes/$CHANGE/: proposal.md, specs/, tasks.md, and design.md when present."
  echo "The implementation is the diff \`git diff origin/$BASE_BR...HEAD\`."
  echo
  echo "Every computational sensor passed this round: \`$(verify_cmd "$WT")\`, \`openspec validate $CHANGE --strict\`,"
  echo "every task in tasks.md checked, no deleted test file, and no added skip."
  echo
  echo "Verify settings this diff changes; for each, check that tasks.md or design.md asks for it:"
  jq -r 'if (.verify_settings | length) == 0 then "- none" else .verify_settings[] | "- \(.)" end' "$rd/sensors.json"
  prev="$(st '.rounds[-1].findings // [] | map(select(.severity == "blocking")) | .[] | "- `\(.file):\(.line)` \(.summary)"')"
  if [ -n "$prev" ]; then
    echo
    echo "Blocking findings of the previous round; check whether each is fixed:"
    echo "$prev"
  fi
}

# record_round <k> <round dir> <start>: append the round to state.json and count it as finished.
record_round() {
  local k="$1" rd="$2" t0="$3" v="$2/verdict.json"
  [ -s "$v" ] || v=/dev/null
  st_set '.rounds += [($s[0]) as $s | ($v[0] // null) as $v | {
      round: $k, sensors: (if ($s.failed | length) == 0 then "pass" else "fail" end), failed: $s.failed,
      verdict: ($v.verdict // null),
      blocking: (if $v then [$v.findings[] | select(.severity == "blocking")] | length else null end),
      findings: ($v.findings // []), question: ($v.question // ""), cost: $c, seconds: $t,
      signature: (($s.failed | map("sensor:" + .)) + $s.blocking_files
                  + ([($v.findings // [])[] | select(.severity == "blocking") | .file])) | unique}]
    | .completed = $k' \
    --argjson k "$k" --slurpfile s "$rd/sensors.json" --slurpfile v "$v" \
    --argjson c "$ROUND_COST" --argjson t "$(($(now) - t0))"
}

# no_progress: the last two rounds failed on the same sensors and the same files.
no_progress() {
  [ "$(st '.rounds | length')" -ge 2 ] || return 1
  [ "$(st '.rounds[-1].signature | length')" -gt 0 ] || return 1
  [ "$(st '.rounds[-1].signature')" = "$(st '.rounds[-2].signature')" ]
}

finish_done() {
  host_ready "$PR" || log "could not take #$PR out of draft"
  st_set '.status = "done"'
  comment_progress 完了
  comment_new render_done
  git -C "$TOP" worktree remove --force "$WT" && git -C "$TOP" branch -q -D "loop/pr-$PR"
  log "done: #$PR meets the completion criteria after $(st .completed) round(s), $(usd "$(st .cost)") estimated"
}

finish_stop() {
  st_set '.status = "stopped" | .stop_reason = $r' --arg r "$1"
  comment_progress 停止
  comment_new render_stopped
  log "stopped: $(stop_reason_text "$1"); the worktree stays at $WT"
}
