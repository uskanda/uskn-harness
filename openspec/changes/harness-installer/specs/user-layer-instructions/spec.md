## Purpose

すべてのリポジトリに共通するエージェント向けの方針（言語、仕様決定の手順、作業ディレクトリ外の扱い、検証の規約）を、ユーザー層の指示として 1 ファイルで届ける。

## ADDED Requirements

### Requirement: 内容
`templates/user/CLAUDE.md` は次を含まなければならない（MUST）: 先頭行の管理印（`<!-- managed by uskn-harness; edit templates/user/CLAUDE.md -->`）、チャットと生成物の言語（日本語）、仕様決定は grilling を通してから OpenSpec の成果物を作ること、作業ディレクトリ外のプロジェクトを直接編集しないこと（PR か handoff）、検証は `make verify` → `pnpm run verify` / `npm run verify` の規約で行うこと。60 行以内。

#### Scenario: 行数
- **WHEN** ファイルの行数を数える
- **THEN** 60 行以下

### Requirement: 配置
`sync` は本ファイルを `~/.claude/CLAUDE.md` にコピーし、`doctor` は配置先が印を持つことを検査しなければならない（MUST）。

#### Scenario: 反映
- **WHEN** テンプレートを編集して `sync` を実行する
- **THEN** `~/.claude/CLAUDE.md` の内容がテンプレートと一致する
