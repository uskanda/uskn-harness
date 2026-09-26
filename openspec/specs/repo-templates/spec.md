# repo-templates Specification

## Purpose
プロダクトリポジトリに置くCLAUDE.mdとverifyターゲットのテンプレート。どちらも中身は最小で、詳細はハーネス側のスキルが持つ。

## Requirements

### Requirement: verify ターゲットのテンプレート
`templates/repo/Makefile` は `verify` ターゲットを持ち、各チェックが道具の不在で落ちない形でなければならない（MUST）。
プレースホルダーには、そのリポジトリのlint、型チェック、テストを入れる。

#### Scenario: 道具が無い環境
- **WHEN** lintの道具が入っていない環境で `make verify` を実行する
- **THEN** そのチェックはスキップされ、終了コードは0

### Requirement: AGENTS.md だけで完結するテンプレート
`templates/repo/` は `CLAUDE.md` を含んではならない（MUST NOT）。
`templates/repo/AGENTS.md` は、Claude固有の記述を書く任意の `## Claude Code` 節を案内しなければならない（MUST）。

#### Scenario: 新しいリポジトリ
- **WHEN** テンプレートをそのまま置く
- **THEN** リポジトリに `CLAUDE.md` は無く、Claudeは `AGENTS.md` を読み、手順はユーザー層のスキルから得る

#### Scenario: Claude 固有の記述が要るリポジトリ
- **WHEN** Claudeだけに効く制約（必要なMCPサーバー、実行してはいけないコマンド）がある
- **THEN** その制約は `AGENTS.md` の `## Claude Code` 節に書かれ、`CLAUDE.md` は作られない
