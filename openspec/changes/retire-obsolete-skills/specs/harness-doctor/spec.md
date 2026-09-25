## ADDED Requirements

### Requirement: OpenSpec のユーザー層コマンドの検査
`doctor` は `~/.claude/commands/opsx/` を検査しなければならない（MUST）。
印（`.uskn-harness-managed`）があり、6つのコマンド（`apply` `archive` `explore` `propose` `sync` `update`）がそろっていれば `ok`。
ディレクトリが無いとき、印が無いとき、コマンドが欠けているときは `warn` とし、欠けたコマンドの名前と `sync` の実行を案内する。
`~/.claude/skills/openspec-*` は検査しない。

#### Scenario: sync 済み
- **WHEN** `sync` が6つのコマンドを置いた状態で `doctor` を実行する
- **THEN** `openspec commands opsx` は `ok`

#### Scenario: コマンドの欠落
- **WHEN** `~/.claude/commands/opsx/archive.md` が無い
- **THEN** `warn` に `archive` と `sync` の案内が含まれ、終了コードは0

### Requirement: 実体の無い symlink の検査
`doctor` は、`~/.claude/skills` の下でハーネスの `skills/` を指し、指す先が存在しないsymlinkを `warn` と報告しなければならない（MUST）。
報告にはsymlinkの名前と `sync` の実行の案内を含める。

#### Scenario: 削除したスキルの symlink
- **WHEN** `~/.claude/skills/pre-merge` が、もう存在しない `skills/git/pre-merge` を指している
- **THEN** `warn` に `pre-merge` と `sync` の案内が含まれ、終了コードは0
