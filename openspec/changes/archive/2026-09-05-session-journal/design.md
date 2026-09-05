## Context

- Stop hook には `transcript_path` が渡る。トランスクリプトは JSONL で、`type: "user"` の行にユーザーメッセージ（文字列か content 配列）、`type: "assistant"` の行に `tool_use`（`name: "Skill"` の `input.skill`）がある。ツール結果も `type: "user"` で来るが `tool_result` ブロックなので除外できる
- SessionEnd の予算は 1.5 秒（`timeout` で最大 60 秒）。トランスクリプトの再解析は Stop 側で済ませ、SessionEnd は commit / push に専念する
- 同じイベントの hook は並列に走るので、`session-start.sh` と `journal-recent.sh` と `session-baseline.sh` は互いの出力に依存しない
- 状態は `${XDG_STATE_HOME:-~/.local/state}/uskn-harness/sessions/<sid>/`（verify-gate と共用）。スキルは `sid8` しか知らないので、ヘルパは `--session <sid8>` から前方一致でディレクトリを探す

## Goals / Non-Goals

**Goals:**
- 軽量: 1 セッション 1 ファイル、数 KB。全文は保存しない
- 決定的な部分は hook が、判断はエージェントが書く。両者が互いを壊さない

**Non-Goals:**
- 意味検索（episodic-memory は必要になったら）
- Codex 等のトランスクリプト形式

## Decisions

1. **ファイル名の slug は後付け、トレーラは `sid8`**。トレーラにパスを入れると改名で切れる。`recall <sid8>` が front matter の `session:` で引く
2. **決定的な部分とエージェント欄は `<!-- agent -->` マーカーで分ける**。再生成はマーカーより前だけを書き換える
3. **プロンプトは先頭 200 字、改行は空白に**。`<private>` タグで囲まれた部分は落とす（humanizer 等と同じ慣習）
4. **`## Changes` は `git diff --stat <baseline HEAD>` と `git status --porcelain` の untracked**。baseline の HEAD は `sessions/<sid>/baseline-head` に別途記録（`session-baseline.sh` を拡張）
5. **block は 1 回**: `sessions/<sid>/journal-prompted` を印にする。理由には journal のパスと `journal` スキル名を書く
6. **journal-end.sh は `git -C ~/.ai-sessions add -A && commit -q -m "<project>: <title or sid8>"` → `timeout 20 git push`**。同時に複数セッションが終わっても commit は直列化されるので競合しない（push は片方が rejected → 次回に fetch --rebase してから push）
7. **journal-recent.sh は `ls -t` で新しい順、awk で 3 節を切り出す**。title は front matter の `title:`、無ければファイル名
8. **`recall` は `rg -n -i` を第一候補、無ければ `grep -rn -i`**
9. **sessions repo は HTTPS URL**（`https://github.com/uskanda/ai-sessions.git`、gh の認証を使う）。`deps.json` に `repos.sessions` を追加

## Risks / Trade-offs

- [journal に機密が写る] → プロンプトは 200 字、ツール出力は含めない、`<private>` を除外。repo は private
- [Stop のたびにトランスクリプトを全走査] → jq 1 パス。数 MB でも 1 秒未満。将来は差分走査
- [push の競合] → 失敗は無視し、次回 `git pull --rebase` してから push
- [journal-prompted の block が邪魔] → 1 回限り。`USKN_SKIP_JOURNAL=1` で無効化

## Migration Plan

hooks.json に 3 つ追加。`sync` で `~/.ai-sessions` を clone。戻すときは hooks.json から外す
