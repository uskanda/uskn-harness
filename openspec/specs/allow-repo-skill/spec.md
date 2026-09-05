# allow-repo-skill Specification

## Purpose
ユーザーが明示的に許可したときだけ、そのセッションに限って他のパスへの書き込みを通す仕組み。ガード hook が読む許可ファイルへの唯一の入口で、エージェントの自発的な実行は認めない。

## Requirements

### Requirement: セッション限定の追記
`allow-repo <path>` は `allow-repo.sh --session <sid8> <path>` でパスの実体を `sessions/<session_id>/allow` に追記し、以後そのセッションのガードが通すようにしなければならない（MUST）。ユーザーの依頼なしにエージェントが自発的に実行してはならない（MUST NOT）。`--list` は現在の許可を表示する。

#### Scenario: 許可
- **WHEN** ユーザーが「dotfiles を直接直してよい」と言い `/allow-repo ~/dotfiles` を実行する
- **THEN** allow に実体パスが 1 行追加され、以後の Write が通る

#### Scenario: 別のセッション
- **WHEN** 新しいセッションを始める
- **THEN** 前のセッションの許可は効いていない
