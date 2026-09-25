## ADDED Requirements

### Requirement: ユーザーだけが起動する
`audit-writing` は、frontmatterに `disable-model-invocation: true` を持たなければならない（MUST）。

#### Scenario: 監査の開始
- **WHEN** ユーザーが `/audit-writing` を打つ
- **THEN** 洗い出しから始まる

#### Scenario: 用語の検査の指摘が多い
- **WHEN** 用語の検査が多くの指摘を返す
- **THEN** エージェントはユーザーに `/audit-writing` の入力を勧める
