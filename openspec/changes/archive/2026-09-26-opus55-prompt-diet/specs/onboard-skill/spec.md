## ADDED Requirements

### Requirement: ユーザーだけが起動する
`onboard-harness` は、frontmatterに `disable-model-invocation: true` を持たなければならない（MUST）。

#### Scenario: 導入の開始
- **WHEN** ユーザーが `/onboard-harness` を打つ
- **THEN** 導入の手順が始まる

#### Scenario: onboard-check の報告
- **WHEN** `uskn-harness onboard-check` が足りない項目を報告する
- **THEN** エージェントはユーザーに `/onboard-harness` の入力を勧める
