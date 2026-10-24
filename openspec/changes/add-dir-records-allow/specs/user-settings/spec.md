## MODIFIED Requirements

### Requirement: sandbox の外で動かすコマンド
設定断片の `sandbox.excludedCommands` は、2つのコマンドに当たるパターンを持たなければならない（MUST）。
2つとは、`uskn-harness` と `chezmoi` である。

#### Scenario: セッションからの sync
- **WHEN** sandboxの有効な端末のセッションで、`uskn-harness sync --dry-run` を実行する
- **THEN** sandboxによる書き込みの拒否が出ずに、予定が出力される
