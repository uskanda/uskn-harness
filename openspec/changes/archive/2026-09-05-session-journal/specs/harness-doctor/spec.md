## ADDED Requirements

### Requirement: sessions repo の検査
`doctor` は `~/.ai-sessions` が git リポジトリであることを検査し、無ければ `warn` としなければならない（MUST）。

#### Scenario: 欠落
- **WHEN** `~/.ai-sessions` が無い
- **THEN** `warn` と `sync` の案内
