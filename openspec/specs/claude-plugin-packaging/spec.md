# claude-plugin-packaging Specification

## Purpose
ハーネスの hook を Claude Code に配るための最小のプラグイン。skills-dir プラグインとして symlink で読み込まれ、marketplace を要しない。

## Requirements

### Requirement: プラグインの構成
`plugins/uskn-harness/` は `.claude-plugin/plugin.json`（name `uskn-harness`、version、description、author）と `hooks/hooks.json` を持ち、hook のコマンドは `${CLAUDE_PLUGIN_ROOT}` 起点の相対パスで自身の `hooks/scripts/` を参照しなければならない（MUST）。プラグイン外へ向く symlink を含んではならない（MUST NOT）。

#### Scenario: symlink で読み込む
- **WHEN** `~/.claude/skills/uskn-harness` が `plugins/uskn-harness` への symlink である
- **THEN** `claude plugin list` に `uskn-harness@skills-dir` が loaded として現れ、SessionStart hook が登録される

### Requirement: 検証を通る
`claude plugin validate --strict plugins/uskn-harness` が成功しなければならない（MUST）。`make verify` はこの検証を含む。

#### Scenario: CI
- **WHEN** `make verify` を実行する
- **THEN** プラグイン検証が実行され、失敗時は verify も失敗する

### Requirement: スキルを同梱しない
プラグインは `skills/` を持たず、スキルの配布は `sync` の symlink に委ねなければならない（MUST）。

#### Scenario: 名前の衝突を避ける
- **WHEN** `~/.claude/skills/commit` が symlink で導入されている
- **THEN** `uskn-harness:commit` のような名前空間付きの重複は現れない
