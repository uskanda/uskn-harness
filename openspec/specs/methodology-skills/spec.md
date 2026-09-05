# methodology-skills Specification

## Purpose
superpowers から fork した 4 つの方法論スキル（TDD、系統的デバッグ、完了前検証、git worktree）の外形と、ハーネスへの適合点。

## Requirements

### Requirement: 出所の表記
fork した各スキルは、ディレクトリに upstream の MIT ライセンス全文を置かなければならない（MUST）。
frontmatter には `license: MIT` を持つ。
本文の先頭には出所（obra/superpowers と版）と、変更点の要約を書く。
`deps.json` の `forks` は `mode: vendored` と `ref`、取り込み日を持つ。

#### Scenario: ライセンスの確認
- **WHEN** `skills/test-driven-development/` を見る
- **THEN** `LICENSE` があり、SKILL.md の frontmatter に `license: MIT` がある

### Requirement: ハーネスのスキル名で参照
fork したスキルどうしの参照は `superpowers:` プレフィックスを持ってはならない（MUST NOT）。
参照はハーネスのスキル名で書く。例は `test-driven-development`、`verification-before-completion`、`writing-for-agents`。

#### Scenario: systematic-debugging から TDD へ
- **WHEN** systematic-debugging の Phase 4 で失敗するテストを書く
- **THEN** 参照先は `test-driven-development` スキル

### Requirement: 検証は repo の規約
`verification-before-completion` は、検証コマンドを repo の規約で見つけることを含まなければならない（MUST）。
規約は `make verify` → `pnpm run verify` / `npm run verify`。
Stop hook（verify gate）が同じコマンドを走らせることも書く。
OpenSpec change では `tasks.md` と突き合わせて完了を判断する。

#### Scenario: 完了報告の前
- **WHEN** エージェントが change の実装を終えたと言おうとする
- **THEN** `make verify` を実行して出力を読み、tasks.md の各項目を確認してから報告する

### Requirement: worktree はルート内
`using-git-worktrees` は、worktree をプロジェクトルート内に置くことを含まなければならない（MUST）。
置き場は native の worktree ツール、または `.worktrees/`。
ルート外は write guard が拒否するため `/allow-repo <path>` が要ることも書く。
baseline の確認は verify 規約に従う。

#### Scenario: worktree の作成
- **WHEN** native の worktree ツールが無く、手で worktree を作る
- **THEN** `.worktrees/<branch>` を使い、gitignore を確認してから作る
