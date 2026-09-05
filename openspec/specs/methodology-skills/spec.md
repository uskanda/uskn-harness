# methodology-skills Specification

## Purpose
superpowersからforkした4つの方法論スキル（TDD、系統的デバッグ、完了前検証、git worktree）の外形と、ハーネスへの適合点。

## Requirements

### Requirement: 出所の表記
forkした各スキルは、ディレクトリにupstreamのMITライセンス全文を置かなければならない（MUST）。
frontmatterには `license: MIT` を持つ。
本文の先頭には出所（obra/superpowersと版）と、変更点の要約を書く。
`deps.json` の `forks` は `mode: vendored` と `ref`、取り込み日を持つ。

#### Scenario: ライセンスの確認
- **WHEN** `skills/test-driven-development/` を見る
- **THEN** `LICENSE` があり、SKILL.mdのfrontmatterに `license: MIT` がある

### Requirement: ハーネスのスキル名で参照
forkしたスキルどうしの参照は `superpowers:` プレフィックスを持ってはならない（MUST NOT）。
参照はハーネスのスキル名で書く。例は `test-driven-development`、`verification-before-completion`、`writing-for-agents`。

#### Scenario: systematic-debugging から TDD へ
- **WHEN** systematic-debuggingのPhase 4で失敗するテストを書く
- **THEN** 参照先は `test-driven-development` スキル

### Requirement: 検証はリポジトリの規約
`verification-before-completion` は、検証コマンドをリポジトリの規約で見つけることを含まなければならない（MUST）。
規約は `make verify` → `pnpm run verify` / `npm run verify`。
Stop hook（verify gate）が同じコマンドを走らせることも書く。
OpenSpec changeでは `tasks.md` と突き合わせて完了を判断する。

#### Scenario: 完了報告の前
- **WHEN** エージェントがchangeの実装を終えたと言おうとする
- **THEN** `make verify` を実行して出力を読み、tasks.mdの各項目を確認してから報告する

### Requirement: worktree はルート内
`using-git-worktrees` は、worktreeをプロジェクトルート内に置くことを含まなければならない（MUST）。
置き場はnativeのworktreeツール、または `.worktrees/`。
ルート外への書き込みはwrite guardが拒否する。`/allow-repo <path>` が要ることも書く。
baselineの確認はverify規約に従う。

#### Scenario: worktree の作成
- **WHEN** nativeのworktreeツールが無く、手でworktreeを作る
- **THEN** `.worktrees/<branch>` を使い、gitignoreを確認してから作る
