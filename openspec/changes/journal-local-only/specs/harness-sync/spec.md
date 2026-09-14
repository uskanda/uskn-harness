## ADDED Requirements

### Requirement: sessions リポジトリの初期化
`sync` は `~/.ai-sessions` が無いとき、`git init` で空のgitリポジトリを作らなければならない（MUST）。
cloneは行わない。既にgitリポジトリがあれば触らず、remoteの有無も問わない。
gitリポジトリでないものがあれば、触らずに `conflict` と報告する。

#### Scenario: 新しいマシン
- **WHEN** `~/.ai-sessions` が無い状態で `sync` を実行する
- **THEN** `~/.ai-sessions` がgitリポジトリとして作られ、`created` と報告される。`git clone` は実行されない

#### Scenario: 既存
- **WHEN** `~/.ai-sessions` がgitリポジトリとして存在する
- **THEN** `ok` として報告され、中身とremoteは変わらない

## REMOVED Requirements

### Requirement: sessions リポジトリの clone
**Reason**: journalをGitHubに置かなくなり、cloneする元が無くなるため。
**Migration**: このdeltaで足した、`git init` で作る要件に置き換える。既存の端末の `~/.ai-sessions` はそのまま使える。
