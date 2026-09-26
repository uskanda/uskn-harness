## ADDED Requirements

### Requirement: ユーザーだけが起動するgitスキル
`rebase`、`cleanup-merged`、`release` は、frontmatterに `disable-model-invocation: true` を持たなければならない（MUST）。
`pr`、`sync-base`、`switch-base` は、モデルから起動できる形のまま置く。

#### Scenario: ユーザーが打つ
- **WHEN** ユーザーが `/rebase` を打つ
- **THEN** `rebase` が実行される

#### Scenario: エージェントが勧める
- **WHEN** エージェントがコミットの整理を勧める
- **THEN** エージェントはユーザーに `/rebase` の入力を頼む

#### Scenario: モデルから起動できるスキル
- **WHEN** ユーザーが「PRを作って」と頼む
- **THEN** エージェントは `pr` を自分で起動できる
