# grilling 記録: loop-vs-workflow

`uskn-loop` の段階1（手元のクローンから手動で起動する）を、Claude Codeのdynamic workflowsで置き換えられるか比べ直す（issue #7）。
grillingの前に、ADR-0007と `docs/loop-engineering-2026-09.md` を読んだ。Workflowの振る舞いは、Claude Codeの文書（workflows、hooks、sub-agents）で調べた。

調べて分かったことは次のとおり。

- Workflowのスクリプトは、シェルとファイルのどちらにも直接触れない。分岐できるのは、エージェントが返した結果だけである
- エージェントごとに使えるツールを絞る方法は、文書に無い。`schema` を渡すと、エージェントはJSONで返す
- Workflowのエージェントでハーネスのhookが動くかは、文書に無い
- `claude -p` から動かせる。費用の上限は、`-p` のときの `--max-budget-usd` だけである

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 段階1をWorkflowで置き換えるか | 置き換えない。`uskn-loop` を続け、ADR-0007の代替案の表にWorkflowを足して、退けた理由を書く | 第1ラウンド Q1 |
| changeの名前とブランチ | `loop-vs-workflow`。mainから `change/loop-vs-workflow` を切る | 最終確認 |
| 仕様 | 振る舞いが変わらないので、仕様は変えない（`skip_specs: true`） | 最終確認 |
| 文書 | ADR-0007の代替案の表と、`docs/loop-engineering-2026-09.md` の実装役と監査役の行に、Workflowを足す | 最終確認 |

## 後回しにしたもの

- なし

## 状態

frontierは空。共有理解は2026-10-24に確認済み。
