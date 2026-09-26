## ADDED Requirements

### Requirement: AGENTS.md だけで完結するテンプレート
`templates/repo/` は `CLAUDE.md` を含んではならない（MUST NOT）。
`templates/repo/AGENTS.md` は、Claude固有の記述を書く任意の `## Claude Code` 節を案内しなければならない（MUST）。

#### Scenario: 新しいリポジトリ
- **WHEN** テンプレートをそのまま置く
- **THEN** リポジトリに `CLAUDE.md` は無く、Claudeは `AGENTS.md` を読み、手順はユーザー層のスキルから得る

#### Scenario: Claude 固有の記述が要るリポジトリ
- **WHEN** Claudeだけに効く制約（必要なMCPサーバー、実行してはいけないコマンド）がある
- **THEN** その制約は `AGENTS.md` の `## Claude Code` 節に書かれ、`CLAUDE.md` は作られない

## REMOVED Requirements

### Requirement: CLAUDE.md テンプレート
**Reason**: Claude Codeはv2.1.277から、`CLAUDE.md` の無いプロジェクトで `AGENTS.md` を読む。v2.1.281からはAmazon Bedrockなどのセッションでも読む。`@AGENTS.md` の1行だけを持つファイルは要らない。
**Migration**: 新しいリポジトリは `templates/repo/AGENTS.md` だけを置く。Claude固有の記述は `AGENTS.md` の `## Claude Code` 節へ書く。既存リポジトリの `CLAUDE.md` はそのままでよい。`@AGENTS.md` の取り込みが残っていても、`AGENTS.md` は2度読まれない。
