## Purpose
ユーザーが `/add-dir` でセッションにディレクトリを足したとき、そのディレクトリをセッションの許可ファイルに記録するhook。
write-guardとbash-guardは許可ファイルを読むので、ルートの外で作業するときにユーザーが打つのは `/add-dir` だけになる。

## ADDED Requirements

### Requirement: 追加されたディレクトリの記録
`DirectoryAdded` のとき、hookは入力の `directory` の実体を、`sessions/<session_id>/allow` に1行追記しなければならない（MUST）。
`<session_id>` は入力の `session_id` である。同じパスが既にあるときは追記しない。
`source` が `slash_command` のときと `register_repo_root` のときの両方で記録する。

#### Scenario: /add-dir の後
- **WHEN** ユーザーが `/add-dir ~/dotfiles` を実行する
- **THEN** 許可ファイルに `~/dotfiles` の実体のパスが1行追加され、以後のWriteが通る

#### Scenario: 同じディレクトリを2回足す
- **WHEN** 同じセッションで `~/dotfiles` を2回足す
- **THEN** 許可ファイルの `~/dotfiles` は1行のまま

#### Scenario: 別のセッション
- **WHEN** 別のセッションを始める
- **THEN** 前のセッションで足したディレクトリへのWriteは拒否される

### Requirement: 記録の通知
記録したとき、hookは `systemMessage` に、記録したパスと、そのパスへの書き込みがこのセッションで許されたことを書かなければならない（MUST）。

#### Scenario: 次のターンのエージェント
- **WHEN** ユーザーが `/add-dir ~/dotfiles` を実行する
- **THEN** hookの出力の `systemMessage` に `~/dotfiles` の実体のパスが含まれる

### Requirement: 失敗しても止めない
入力が読めないとき、`directory` が無いとき、セッションの状態ディレクトリが無いとき、hookは何も出力せず終了コード0で終わらなければならない（MUST）。

#### Scenario: JSONでない入力
- **WHEN** stdinがJSONでない
- **THEN** 出力は空で、終了コードは0

#### Scenario: 存在しないディレクトリ
- **WHEN** 入力の `directory` が存在しない
- **THEN** 許可ファイルは変わらず、出力は空
