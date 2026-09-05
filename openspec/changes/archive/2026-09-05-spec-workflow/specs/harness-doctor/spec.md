## ADDED Requirements

### Requirement: schema の検査
`doctor` は `~/.local/share/openspec/schemas/uskn` の存在と向き先を他の symlink と同じ規則で検査しなければならない（MUST）。

#### Scenario: 欠落
- **WHEN** symlink が無い
- **THEN** `warn` として報告され、`sync` の実行が案内される
