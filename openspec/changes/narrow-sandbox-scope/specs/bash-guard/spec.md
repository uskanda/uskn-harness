## ADDED Requirements

### Requirement: 途中に出てくる外の道具の知らせ
sandboxの外に出す道具が、コマンド全体の先頭にないとき、hookは `additionalContext` で知らせなければならない（MUST）。
外に出す道具とは、liveの `sandbox.excludedCommands` のパターンに当たるものである。
先頭にないとは、コマンド全体が複数の単純なコマンドから成る（パイプ、`&&`、`;`、かっこを含む）か、その道具の前に代入や `sudo` などが付くことを言う。
`excludedCommands` がsandboxの外で動かすのは、1つの単純なコマンドだけから成り、その先頭がパターンと一致するコマンドだけであるため。
知らせには、その道具がsandboxの中で動くことと、失敗したら単独で実行し直すことを書く。
パターンは、liveの `~/.claude/settings.json` から読む。`CLAUDE_CONFIG_DIR` があれば、その下から読む。
拒否してはならない（MUST NOT）。denyパターンに当たるときは、拒否だけを返す。

#### Scenario: cd の後の push
- **WHEN** liveの `sandbox.excludedCommands` に `git *` がある状態で、`cd sub && git push -u origin HEAD` を実行しようとする
- **THEN** `additionalContext` に `git push` と、単独で実行し直すことが含まれ、拒否はされない

#### Scenario: パイプの前の push
- **WHEN** 同じ状態で、`git push -u origin HEAD 2>&1 | tail -1` を実行しようとする
- **THEN** `additionalContext` に `git push` が含まれ、拒否はされない

#### Scenario: 先頭の push
- **WHEN** 同じ状態で、`git push -u origin HEAD` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: 一覧に無い道具
- **WHEN** 同じ状態で、`cd sub && make test` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: 設定が読めない
- **WHEN** liveの `~/.claude/settings.json` が無い
- **THEN** この知らせは出さない
