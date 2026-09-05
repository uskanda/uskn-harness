## ADDED Requirements

### Requirement: Session トレーラ
`commit` は `<repo-context>` に `session:` があるとき、各コミットメッセージの末尾に `Session: <sid8>` トレーラを付けなければならない（MUST）。無いときは付けない。

#### Scenario: セッション内のコミット
- **WHEN** `<repo-context>` に `session: 3f2a9c1d` がある状態で `/commit` を実行する
- **THEN** 各コミットの末尾に `Session: 3f2a9c1d` がある
