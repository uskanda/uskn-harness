## ADDED Requirements

### Requirement: DirectoryAdded の配線
`plugins/uskn-harness/hooks/hooks.json` は、`DirectoryAdded` に、追加されたディレクトリを記録するhookを1つ登録しなければならない（MUST）。
matcherと `if` は付けない。`slash_command` と `register_repo_root` の両方で起動するため。

#### Scenario: hooks.json の構成
- **WHEN** `hooks.json` の `DirectoryAdded` を読む
- **THEN** hookは1つで、matcherと `if` のどちらも持たない
