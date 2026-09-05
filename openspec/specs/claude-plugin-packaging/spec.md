# claude-plugin-packaging Specification

## Purpose
ハーネスのhookをClaude Codeに配るための最小のプラグイン。skills-dirプラグインとしてsymlinkで読み込まれ、marketplaceを要しない。

## Requirements

### Requirement: プラグインの構成
`plugins/uskn-harness/` は `.claude-plugin/plugin.json` と `hooks/hooks.json` を持たなければならない（MUST）。
`plugin.json` はname `uskn-harness`、version、description、authorを持つ。
hookのコマンドは `${CLAUDE_PLUGIN_ROOT}` 起点の相対パスで自身の `hooks/scripts/` を参照する。
プラグイン外へ向くsymlinkを含んではならない（MUST NOT）。

#### Scenario: symlink で読み込む
- **WHEN** `~/.claude/skills/uskn-harness` が `plugins/uskn-harness` へのsymlinkである
- **THEN** `claude plugin list` に `uskn-harness@skills-dir` がloadedとして現れ、SessionStart hookが登録される

### Requirement: 検証を通る
`claude plugin validate --strict plugins/uskn-harness` が成功しなければならない（MUST）。`make verify` はこの検証を含む。

#### Scenario: CI
- **WHEN** `make verify` を実行する
- **THEN** プラグイン検証が実行され、失敗時はverifyも失敗する

### Requirement: スキルを同梱しない
プラグインは `skills/` を持たず、スキルの配布は `sync` のsymlinkに委ねなければならない（MUST）。

#### Scenario: 名前の衝突を避ける
- **WHEN** `~/.claude/skills/commit` がsymlinkで導入されている
- **THEN** `uskn-harness:commit` のような名前空間付きの重複は現れない
