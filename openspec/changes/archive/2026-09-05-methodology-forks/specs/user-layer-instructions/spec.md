## ADDED Requirements

### Requirement: 方法論スキルへの導線
ユーザー層の `CLAUDE.md` は、方法論スキルへの導線を含まなければならない（MUST）。
実装は `test-driven-development`、原因調査は `systematic-debugging` に従う。
完了と言う前は `verification-before-completion`、隔離した作業場所が要るときは `using-git-worktrees` に従う。

#### Scenario: テスト失敗
- **WHEN** テストが失敗し、原因が分からない
- **THEN** エージェントは修正案を出す前に `systematic-debugging` に従って原因を調べる
