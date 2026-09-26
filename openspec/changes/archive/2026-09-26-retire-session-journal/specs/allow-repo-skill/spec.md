## MODIFIED Requirements

### Requirement: セッション限定の追記
`allow-repo <path>` は `allow-repo.sh --session <sid8> <path>` を呼ばなければならない（MUST）。
`<sid8>` はセッションIDの先頭8文字で、`${CLAUDE_SESSION_ID}` から得る。置換されないときは環境変数 `CLAUDE_CODE_SESSION_ID` から得る。
スクリプトは `--session` が無いか空のとき、環境変数 `CLAUDE_CODE_SESSION_ID` の先頭8文字を使う。
スクリプトはパスの実体を `sessions/<session_id>/allow` に追記する。
以後そのセッションのガードは、そのパスへの書き込みを通さなければならない（MUST）。
ユーザーの依頼なしにエージェントが自発的に実行してはならない（MUST NOT）。`--list` は現在の許可を表示する。

#### Scenario: 許可
- **WHEN** ユーザーが「dotfilesを直接直してよい」と言い `/allow-repo ~/dotfiles` を実行する
- **THEN** allowに実体パスが1行追加され、以後のWriteが通る

#### Scenario: 別のセッション
- **WHEN** 新しいセッションを始める
- **THEN** 前のセッションの許可は効いていない

#### Scenario: session 行の無い repo-context
- **WHEN** `<repo-context>` にsession行が無いセッションで `/allow-repo ~/dotfiles` を実行する
- **THEN** セッションIDの先頭8文字で許可が記録される

#### Scenario: --session を省いた実行
- **WHEN** `CLAUDE_CODE_SESSION_ID` が設定された環境で、`--session` を付けずにスクリプトを実行する
- **THEN** その値の先頭8文字のセッションに許可が記録される
