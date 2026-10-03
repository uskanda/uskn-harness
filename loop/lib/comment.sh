#!/usr/bin/env bash
# Comments of bin/uskn-loop on the PR or MR (openspec: loop-progress-comment). Sourced, not executed. Expects STATE,
# STATE_DIR, PR, ROUNDS, PR_BUDGET_USD, and the host functions.
#
# One progress comment (marked PROGRESS_MARK) is rewritten from state.json at every phase. The result of the run
# goes into a new comment of its own. Comments carry summaries and locations only: raw outputs stay in STATE_DIR.

PROGRESS_MARK='<!-- uskn-loop -->'

# _findings_md <jq array of findings> <severity>: one bullet per finding of that severity, or 「なし」.
_findings_md() {
  jq -r --arg s "$2" '[.[] | select(.severity == $s)] |
    if length == 0 then "- なし" else .[] | "- `\(.file):\(.line)` \(.summary)" end' <<< "$1"
}

render_progress() {
  local phase change completed cost
  phase="$(st .phase)"; change="$(st .change)"; completed="$(st .completed)"; cost="$(st .cost)"
  echo "$PROGRESS_MARK"
  echo "### uskn-loop：$phase"
  echo
  case "$phase" in
    完了) echo "change \`$change\` は完了基準を満たしました。" ;;
    停止) echo "change \`$change\` のループを止めました。理由は別のコメントにあります。" ;;
    *) echo "change \`$change\` を、実装と監査のループで進めています（ラウンドの上限は${ROUNDS}回）。" ;;
  esac
  echo
  echo "| ラウンド | 検証 | 修正必須 | 費用の見積もり | 所要時間 |"
  echo "|---|---|---|---|---|"
  jq -r '
    def money: (. * 100 | round) as $c | "$\($c / 100 | floor).\($c % 100 | tostring | if length < 2 then "0" + . else . end)";
    def minutes: if . < 60 then "1分未満" else "\((. + 59) / 60 | floor)分" end;
    .rounds[] | "| \(.round) | \(if .sensors == "pass" then "成功" else "失敗（" + (.failed | join("、")) + "）" end) | \(.blocking // "-") | \(.cost | money) | \(.seconds | minutes) |"' "$STATE"
  case "$phase" in 実装中 | 検証中 | 監査中) echo "| $((completed + 1)) | $phase | | | |" ;; esac
  echo
  echo "費用の見積もりの合計は $(usd "$cost") です（上限 $(usd "$PR_BUDGET_USD")）。"
  last_findings_block
  echo
  echo "ログ：\`$STATE_DIR\`"
}

# last_findings_block: the latest round's findings, folded.
last_findings_block() {
  local f n
  f="$(st '.rounds[-1].findings // []')"
  n="$(jq length <<< "$f")"
  [ "$n" -gt 0 ] || return 0
  echo
  echo "<details><summary>最新の指摘（${n}件）</summary>"
  echo
  jq -r '.[] | "- \(if .severity == "blocking" then "修正必須" else "推奨" end)：`\(.file):\(.line)` \(.summary)"' <<< "$f"
  echo
  echo "</details>"
}

render_done() {
  local change
  change="$(st .change)"
  echo "<!-- uskn-loop:done -->"
  echo "### uskn-loop：完了しました"
  echo
  echo "change \`$change\` は$(st .completed)ラウンドで完了基準を満たしました。費用の見積もりの合計は $(usd "$(st .cost)") です。"
  echo
  echo "推奨の指摘："
  echo
  _findings_md "$(st '.rounds[-1].findings // []')" advisory
  echo
  echo "次の操作："
  echo
  echo "1. 変更を確認します。"
  echo "2. このブランチで \`/archive-push $change\` を実行します。"
  echo "3. マージします。"
}

# render_stopped: why the loop stopped, the auditor's question, what still blocks, and how to go on.
render_stopped() {
  local q
  q="$(st '.rounds[-1].question // ""')"
  echo "<!-- uskn-loop:stopped -->"
  echo "### uskn-loop：停止しました"
  echo
  echo "停止条件「$(stop_reason_text "$(st .stop_reason)")」に当たったため、ループを止めました。PRはdraftのままです。"
  if [ -n "$q" ]; then
    echo
    echo "監査役の問い：$q"
  fi
  echo
  echo "残っている修正必須の指摘："
  echo
  jq -r '(.rounds[-1].failed // [] | map("- 計算的センサー：" + .)) + ((.rounds[-1].findings // []) |
      map(select(.severity == "blocking") | "- `\(.file):\(.line)` \(.summary)")) |
      if length == 0 then "- なし" else .[] end' "$STATE"
  echo
  echo "続けるときは、手元のクローンで \`uskn-loop run $PR\` を実行してください。"
}

stop_reason_text() {
  case "$1" in
    rounds) echo "ラウンドの上限（${ROUNDS}回）" ;;
    budget) echo "費用の上限（$(usd "$PR_BUDGET_USD")）" ;;
    no-progress) echo "2ラウンド続けて進展なし" ;;
    question) echo "監査役の問い" ;;
    no-verdict) echo "監査役の判定なし" ;;
    push) echo "pushの拒否" ;;
    conflict) echo "基底ブランチとの衝突" ;;
    *) echo "$1" ;;
  esac
}

# comment_progress <phase>: record the phase and rewrite the progress comment (create it, or find it by its mark,
# the first time). A failing host call is reported and the loop goes on.
comment_progress() {
  local id body
  st_set '.phase = $p' --arg p "$1"
  body="$STATE_DIR/progress.md"
  render_progress > "$body"
  id="$(st '.comment_id // empty')"
  [ -n "$id" ] || id="$(host_comment_find "$PR" "$PROGRESS_MARK" "$ME" 2>/dev/null || true)"
  if [ -n "$id" ] && host_comment_update "$PR" "$id" "$body"; then :
  else
    id="$(host_comment_create "$PR" "$body" || true)"
  fi
  if [ -n "$id" ]; then st_set '.comment_id = $i' --arg i "$id"; else log "could not write the progress comment"; fi
}

# comment_new <render function>: post a new comment.
comment_new() {
  local body="$STATE_DIR/$1.md"
  "$1" > "$body"
  host_comment_create "$PR" "$body" >/dev/null || log "could not post the comment ($1)"
}
