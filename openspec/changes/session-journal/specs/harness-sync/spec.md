## ADDED Requirements

### Requirement: sessions repo の clone
`sync` は `~/.ai-sessions` が無いとき `deps.json` の `repos.sessions.url` から clone しなければならない（MUST）。既にあれば触らない。

#### Scenario: 既存
- **WHEN** `~/.ai-sessions` が git リポジトリとして存在する
- **THEN** `ok` として報告される
