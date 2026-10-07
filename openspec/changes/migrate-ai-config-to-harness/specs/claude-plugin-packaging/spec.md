## MODIFIED Requirements

### Requirement: プラグインの構成
`plugins/` の下の各プラグインは、`.claude-plugin/plugin.json` と `hooks/hooks.json` を持たなければならない（MUST）。
`plugin.json` はディレクトリ名と同じname、version、description、authorを持つ。
hookのコマンドは、`${CLAUDE_PLUGIN_ROOT}` 起点の相対パスで自身のプラグインの中のファイルを参照する。
プラグイン外へ向くsymlinkを含んではならない（MUST NOT）。

#### Scenario: symlink で読み込む
- **WHEN** `~/.claude/skills/uskn-harness` が `plugins/uskn-harness` へのsymlinkである
- **THEN** `claude plugin list` に `uskn-harness@skills-dir` がloadedとして現れ、SessionStart hookが登録される

#### Scenario: 2 つ目のプラグイン
- **WHEN** `~/.claude/skills/uskn-notify` が `plugins/uskn-notify` へのsymlinkである
- **THEN** `claude plugin list` に `uskn-notify@skills-dir` がloadedとして現れ、Stop hookが登録される

### Requirement: 検証を通る
`plugins/` の下の各プラグインについて、`claude plugin validate --strict` が成功しなければならない（MUST）。`make verify` はこの検証を含む。

#### Scenario: CI
- **WHEN** `make verify` を実行する
- **THEN** `plugins/uskn-harness` と `plugins/uskn-notify` の検証が実行され、どちらかが失敗すればverifyも失敗する

### Requirement: スキルを同梱しない
`plugins/` の下の各プラグインは `skills/` を持たず、スキルの配布は `sync` のsymlinkに委ねなければならない（MUST）。

#### Scenario: 名前の衝突を避ける
- **WHEN** `~/.claude/skills/commit` がsymlinkで導入されている
- **THEN** `uskn-harness:commit` のような名前空間付きの重複は現れない
