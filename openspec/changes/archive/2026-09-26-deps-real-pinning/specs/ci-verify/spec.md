## ADDED Requirements

### Requirement: Claude Code の版は固定しない
workflowはClaude CodeのCLI `@anthropic-ai/claude-code` を、版を指定せずに入れなければならない（MUST）。
最新版の利用を妨げないためで、問題が起きたときはこのリポジトリの更新で対処する。
`make verify` のbatsが、workflowの導入のコマンドに版の指定が無いことを検査する。

#### Scenario: Claude Code の新しい版
- **WHEN** Claude Codeの新しい版が出たあとにworkflowが走る
- **THEN** workflowを変えずに、その版で `claude plugin validate` が実行される

#### Scenario: 版を書き足す
- **WHEN** workflowの導入のコマンドを `@anthropic-ai/claude-code@<version>` に変える
- **THEN** `make verify` のbatsが失敗する
