## Purpose

ユーザーが明示的に許可したときだけ、そのセッションで他のパスへの書き込みを通す。

## ADDED Requirements

### Requirement: セッション限定の追記
`allow-repo <path>` は `allow-repo.sh --session <sid8> <path>` でパスの実体を `sessions/<session_id>/allow` に追記し、以後そのセッションのガードが通すようにしなければならない（MUST）。ユーザーの依頼なしにエージェントが自発的に実行してはならない（MUST NOT）。`--list` は現在の許可を表示する。

#### Scenario: 許可
- **WHEN** ユーザーが「dotfiles を直接直してよい」と言い `/allow-repo ~/dotfiles` を実行する
- **THEN** allow に実体パスが 1 行追加され、以後の Write が通る

#### Scenario: 別のセッション
- **WHEN** 新しいセッションを始める
- **THEN** 前のセッションの許可は効いていない
