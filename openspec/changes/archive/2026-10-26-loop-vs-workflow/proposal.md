# Proposal

## Why

ADR-0007は、仕様PRのループを `uskn-loop` として自作すると決めた。そのとき比べた案に、Claude Codeのdynamic workflowsは無かった。
Workflowは、続けるか止めるかをスクリプトが決め、エージェントごとに新しい文脈で動く。ADR-0007が `claude -p` を選んだ理由の一部を満たすので、退けた理由を残す（issue #7）。

## What Changes

- ADR-0007の「検討した代替案」の表に、Workflowで段階1を動かす案と、退けた理由を足す
- `docs/loop-engineering-2026-09.md` の実装役と監査役の行の「退けた案」に、Workflowを足す
- `uskn-loop` とその仕様は変えない

## Capabilities

### New Capabilities

- なし

### Modified Capabilities

- なし

## Impact

- `docs/adr/0007-loop-runner.md`
- `docs/loop-engineering-2026-09.md`
