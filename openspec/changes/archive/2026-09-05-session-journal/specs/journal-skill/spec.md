## Purpose

エージェントが判断の記録（決定、未解決、次の一手）と slug を journal に書くための手順。

## ADDED Requirements

### Requirement: 判断の追記
`journal` スキルは現在のセッションの journal（`journal-update.sh --session <sid8> --path`）を開き、`## Decisions`、`## Open`、`## Next` を会話の事実に基づいて書き、必要なら `--slug` で名前を付けなければならない（MUST）。決定的な部分を書き換えてはならない（MUST NOT）。

#### Scenario: block からの復帰
- **WHEN** Stop hook が journal の記入を求めて block した
- **THEN** スキルは 3 節を埋め、slug を付け、作業を終える
