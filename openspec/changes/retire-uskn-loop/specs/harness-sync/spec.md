## MODIFIED Requirements

### Requirement: 実行ファイルの公開
`sync` は `~/.local/bin/uskn-harness` を `bin/uskn-harness` へのsymlinkにしなければならない（MUST）。
`sync --remove` は、このsymlinkを取り除かなければならない（MUST）。
`~/.local/bin/uskn-loop` がハーネスの中を指すsymlinkか、指す先の無いsymlinkのとき、`sync` はそれを取り除かなければならない（MUST）。
`~/.local/bin/uskn-loop` がそれ以外のものであるとき、`sync` は触ってはならない（MUST NOT）。

#### Scenario: PATH から呼べる
- **WHEN** `sync` 後に新しいシェルを開く
- **THEN** `uskn-harness doctor` が実行できる

#### Scenario: ループのコマンド
- **WHEN** `sync` 後に新しいシェルを開く
- **THEN** `uskn-loop` は見つからない

#### Scenario: 廃止したループのコマンド
- **WHEN** 以前の `sync` の作った `~/.local/bin/uskn-loop` が残る端末で、`sync` を実行する
- **THEN** `~/.local/bin/uskn-loop` は消え、`removed` として報告される

#### Scenario: ユーザーが置いた同名のファイル
- **WHEN** `~/.local/bin/uskn-loop` が通常のファイルとして存在する
- **THEN** `sync` はそのファイルを残す
