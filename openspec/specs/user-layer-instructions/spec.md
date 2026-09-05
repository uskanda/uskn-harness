# user-layer-instructions Specification

## Purpose
すべてのリポジトリに共通するエージェント向けの方針（言語、仕様決定の手順、作業ディレクトリ外の扱い、検証の規約）を、ユーザー層の指示として 1 ファイルで届ける。

## Requirements

### Requirement: 内容
`templates/user/CLAUDE.md` は次を含まなければならない（MUST）。

- 先頭行の管理印（`<!-- managed by uskn-harness; edit templates/user/CLAUDE.md -->`）
- チャットと生成物の言語（日本語）
- 仕様決定は grilling を通してから OpenSpec の成果物を作ること
- 作業ディレクトリ外のプロジェクトを直接編集しないこと。他 repo は PR か handoff で渡す
- 検証は `make verify` → `pnpm run verify` / `npm run verify` の規約に従うこと

全体で 60 行以内。

#### Scenario: 行数
- **WHEN** ファイルの行数を数える
- **THEN** 60 行以下

### Requirement: 配置
`sync` は本ファイルを `~/.claude/CLAUDE.md` にコピーし、`doctor` は配置先が印を持つことを検査しなければならない（MUST）。

#### Scenario: 反映
- **WHEN** テンプレートを編集して `sync` を実行する
- **THEN** `~/.claude/CLAUDE.md` の内容がテンプレートと一致する

### Requirement: Writing 節
ユーザー層の `CLAUDE.md` は、文章の指針への導線を含まなければならない（MUST）。
日本語の文章は `ja-writing`、人が読む英語の文章は `en-writing` に従う。
Markdown を書いたあとに出る textlint の指摘は、直してから終える。

#### Scenario: hook の指摘
- **WHEN** textlint hook が指摘を返す
- **THEN** エージェントは指摘を直してから作業を終えたと報告する

### Requirement: UI 節
ユーザー層の `CLAUDE.md` は、UI を作る・直すときは `ui-guidelines` に従い、`DESIGN.md` と `PRODUCT.md` を正本にすることを含まなければならない（MUST）。

#### Scenario: UI 作業の開始
- **WHEN** ユーザーが画面の作成や修正を頼む
- **THEN** エージェントは `ui-guidelines` を読んでから着手する

### Requirement: 方法論スキルへの導線
ユーザー層の `CLAUDE.md` は、方法論スキルへの導線を含まなければならない（MUST）。
実装は `test-driven-development`、原因調査は `systematic-debugging` に従う。
完了と言う前は `verification-before-completion`、隔離した作業場所が要るときは `using-git-worktrees` に従う。

#### Scenario: テスト失敗
- **WHEN** テストが失敗し、原因が分からない
- **THEN** エージェントは修正案を出す前に `systematic-debugging` に従って原因を調べる
