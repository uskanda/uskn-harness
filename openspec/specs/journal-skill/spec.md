# journal-skill Specification

## Purpose
エージェントが判断の記録（決定、未解決、次の一手）とslugをjournalに書くための手順。事実の部分はhookが書くので、スキルは判断だけを受け持つ。

## Requirements

### Requirement: 判断の追記
`journal` スキルは現在のセッションのjournalを `journal-update.sh --session <sid8> --path` で開かなければならない（MUST）。
`## Decisions`、`## Open`、`## Next` を会話の事実に基づいて書き、必要なら `--slug` で名前を付ける。
決定的な部分を書き換えてはならない（MUST NOT）。

#### Scenario: block からの復帰
- **WHEN** Stop hookがjournalの記入を求めてblockした
- **THEN** スキルは3節を埋め、slugを付け、作業を終える
