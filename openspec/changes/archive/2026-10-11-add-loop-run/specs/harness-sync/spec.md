## MODIFIED Requirements

### Requirement: 実行ファイルの公開
`sync` は `~/.local/bin/uskn-harness` を `bin/uskn-harness` へのsymlinkにしなければならない（MUST）。
`sync` は `~/.local/bin/uskn-loop` を `bin/uskn-loop` へのsymlinkにしなければならない（MUST）。
`sync --remove` は、この2つのsymlinkを取り除かなければならない（MUST）。

#### Scenario: PATH から呼べる
- **WHEN** `sync` 後に新しいシェルを開く
- **THEN** `uskn-harness doctor` が実行できる

#### Scenario: ループのコマンド
- **WHEN** `sync` 後に新しいシェルを開く
- **THEN** `uskn-loop` が実行できる
