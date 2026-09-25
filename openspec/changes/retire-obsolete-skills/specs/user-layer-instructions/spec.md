## MODIFIED Requirements

### Requirement: 方法論スキルへの導線
ユーザー層の `CLAUDE.md` は、方法論スキルへの導線を含まなければならない（MUST）。
実装は `test-driven-development`、原因調査は `systematic-debugging` に従う。
完了と言う前は `verify` に従う。隔離した作業場所が要るときは、エージェントのネイティブのworktreeの機能を使う。
`sync` が導入しないスキルの名前を書いてはならない（MUST NOT）。

#### Scenario: テスト失敗
- **WHEN** テストが失敗し、原因が分からない
- **THEN** エージェントは修正案を出す前に `systematic-debugging` に従って原因を調べる

#### Scenario: 削除したスキル
- **WHEN** `templates/user/CLAUDE.md` を `verification-before-completion`、`using-git-worktrees`、`pre-merge` で検索する
- **THEN** 一致しない
