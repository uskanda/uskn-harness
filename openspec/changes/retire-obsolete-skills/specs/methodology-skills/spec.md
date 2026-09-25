## MODIFIED Requirements

### Requirement: ハーネスのスキル名で参照
forkしたスキルどうしの参照は `superpowers:` プレフィックスを持ってはならない（MUST NOT）。
参照はハーネスのスキル名で書く。例は `test-driven-development`、`systematic-debugging`、`verify`、`writing-for-agents`。

#### Scenario: systematic-debugging から TDD へ
- **WHEN** systematic-debuggingのPhase 4で失敗するテストを書く
- **THEN** 参照先は `test-driven-development` スキル

#### Scenario: 修正の確認
- **WHEN** systematic-debuggingのPhase 4で、修正が効いたと言う前に確認する
- **THEN** 参照先は `verify` スキル

## REMOVED Requirements

### Requirement: 検証はリポジトリの規約
**Reason**: `verification-before-completion` を削除し、完了前の確認を `verify` に統合したため。
**Migration**: 完了の根拠を示す規則は `verify-skill` の「完了の根拠」が持つ。検証規約の探索は同じく「規約の探索と実行」が持つ。

### Requirement: worktree はルート内
**Reason**: `using-git-worktrees` を削除したため。隔離した作業場所は、エージェントのネイティブのworktreeの機能で作る。
**Migration**: Claude Codeのネイティブのworktreeは、プロジェクトルートの中（`.claude/worktrees/`）に作られる。ルートの外への書き込みは、引き続きwrite guardが拒否する。
