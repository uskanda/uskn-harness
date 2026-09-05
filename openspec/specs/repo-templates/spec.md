# repo-templates Specification

## Purpose
プロダクトリポジトリに置くCLAUDE.mdとverifyターゲットのテンプレート。どちらも中身は最小で、詳細はハーネス側のスキルが持つ。

## Requirements

### Requirement: CLAUDE.md テンプレート
`templates/repo/CLAUDE.md` は `@AGENTS.md` の1行と、Claude固有の数行だけを持たなければならない（MUST）。
手順やコーディング規約を含んではならない（MUST NOT）。それらはスキルとユーザー層の指示が持つ。

#### Scenario: 新しいリポジトリ
- **WHEN** テンプレートをそのまま置く
- **THEN** Claudeは `AGENTS.md` を読み、手順はユーザー層のスキルから得る

### Requirement: verify ターゲットのテンプレート
`templates/repo/Makefile` は `verify` ターゲットを持ち、各チェックが道具の不在で落ちない形でなければならない（MUST）。
プレースホルダには、そのリポジトリのlint、型チェック、テストを入れる。

#### Scenario: 道具が無い環境
- **WHEN** lintの道具が入っていない環境で `make verify` を実行する
- **THEN** そのチェックはスキップされ、終了コードは0
