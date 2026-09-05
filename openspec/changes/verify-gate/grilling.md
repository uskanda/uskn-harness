# grilling 記録: verify-gate

本 change の決定は Phase 2 の grilling（`docs/proposal-2026-09.md` §14 第6ラウンド）と、ハーネス全体の
grilling（同 §10）で確定済み。該当箇所の抜粋。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 検証の強制 | スキル + Stop hook。検証コマンドは規約（`make verify` → `pnpm run verify` / `npm run verify`） | 第1ラウンド Q8、第2ラウンド Q17 |
| Stop hook の挙動 | 作業ツリーがセッション開始時から変化したときだけ実行。失敗は `decision: block`。`stop_hook_active` で再ブロックしない。`USKN_SKIP_VERIFY=1` で回避。無ければ黙って通す | 第6ラウンド Q43 |
| サブエージェント | `agent_type` があるときは動かさない | 第6ラウンド前提 |

## 後回しにしたもの

- PostToolUse で src 変更時に対応テスト未変更を警告する案（第1ラウンド Q8 の C）は誤検知が多いため見送り

## 状態

frontier は空。共有理解は 2026-09-05 に確認済み。
