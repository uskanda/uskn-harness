## ADDED Requirements

### Requirement: OpenSpec schema の symlink
`sync` は `~/.local/share/openspec/schemas/uskn` をハーネスの `schemas/uskn` への symlink にしなければならない（MUST）。衝突時の扱いは他の symlink と同じ。`sync --remove` はこの symlink も取り除く。

#### Scenario: 初回
- **WHEN** 未導入の環境で `sync` を実行する
- **THEN** symlink が作られ、`openspec schema which uskn` が user レベルを返す
