# harness-doctor Specification

## Purpose
ハーネスの導入状態を検査し、壊れている箇所と原因を人が読める形で示す。run_onceやCIからも使えるよう、問題があれば非ゼロで終わる。

## Requirements

### Requirement: 検査項目
`uskn-harness doctor` は次を検査し、各項目を `ok` / `warn` / `fail` で報告しなければならない（MUST）。

- 参照点の存在と向き先
- mise、node、jqの有無
- `deps.json` でピン止めしたnpmのCLIの版
- `~/.claude/skills` の各symlinkの存在と向き先
- chezmoi管理の同名スキルとの衝突
- プラグインsymlinkと `claude plugin validate` の結果
- サードパーティスキルの有無
- `~/.claude/CLAUDE.md` の管理印

#### Scenario: 健全な環境
- **WHEN** `sync` 直後に `doctor` を実行する
- **THEN** すべて `ok` で終了コード0

#### Scenario: 向き先が違う symlink
- **WHEN** `~/.claude/skills/commit` が別のパスを指すsymlink
- **THEN** その項目は `fail` で、終了コードは1

### Requirement: 終了コード
`fail` が1つでもあれば終了コード1、`warn` のみなら0で終わらなければならない（MUST）。

#### Scenario: 衝突だけがある
- **WHEN** chezmoi管理の同名スキルによる `conflict` だけが検出される
- **THEN** その項目は `warn` で、終了コードは0

### Requirement: 書き込みをしない
`doctor` はファイルシステムを変更してはならない（MUST NOT）。

#### Scenario: 読み取り専用
- **WHEN** `doctor` を実行する
- **THEN** `~/.claude` と `~/.local` の内容は実行前後で同一

### Requirement: schema の検査
`doctor` は `~/.local/share/openspec/schemas/uskn` の存在と向き先を他のsymlinkと同じ規則で検査しなければならない（MUST）。

#### Scenario: 欠落
- **WHEN** symlinkが無い
- **THEN** `warn` として報告され、`sync` の実行が案内される

### Requirement: npm global CLI の版の確認
`doctor` は `deps.json` の `clis` の各項目について、入っている版がピンと一致すれば `ok`、無いか異なれば `warn` を報告しなければならない（MUST）。

#### Scenario: 版の不一致
- **WHEN** textlint 15.0.0が入っていて `deps.json` は15.8.0を指す
- **THEN** `warn` に両方の版が含まれる

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

### Requirement: サードパーティスキルの ref の確認
`doctor` は、`via` が `skills` のサードパーティスキルごとに、lockファイルの `ref` とピンの差を報告しなければならない（MUST）。
同じなら `ok`、違うかlockの項目が `ref` を持たなければ `warn` とし、両方の値と `sync` の案内を含める。
lockに項目が無いときも `warn` とする。

#### Scenario: ref の不一致
- **WHEN** lockのgrillingの項目が `ref` を持たない
- **THEN** grillingは `warn` で、ピンの `ref` と `sync` の案内が含まれ、終了コードは0

#### Scenario: ピンと同じ
- **WHEN** lockのgrillingの `ref` が `deps.json` と同じ
- **THEN** grillingは `ok`

### Requirement: Impeccable の版の確認
Impeccableの `SKILL.md` の `version` がピンと違うとき、`doctor` は `warn` を報告しなければならない（MUST）。
`warn` には両方の版を含める。

#### Scenario: 版が古い
- **WHEN** 導入済みの `SKILL.md` が `version: 4.2.0` で、`deps.json` は4.3.1を指す
- **THEN** impeccableは `warn` で、4.2.0と4.3.1の両方が含まれる

### Requirement: Impeccable の agent の確認
`remove_agents` に挙げたagentのファイルが残っているとき、`doctor` は `warn` を報告しなければならない（MUST）。

#### Scenario: agent が残っている
- **WHEN** `~/.claude/agents/impeccable-documenter.md` がある
- **THEN** そのファイル名と `sync` の案内を含む `warn` が出る

### Requirement: 鮮度警告の設定の確認
環境変数 `IMPECCABLE_NO_STALENESS_CHECK=1` がどこにも設定されていないとき、`doctor` は `warn` を報告しなければならない（MUST）。
確かめる場所は、`~/.claude/settings.json` の `env` と、`doctor` 自身の環境の2つ。
この設定はdotfilesが管理するので、`sync` は書かない。

#### Scenario: 設定が無い
- **WHEN** `~/.claude/settings.json` の `env` に `IMPECCABLE_NO_STALENESS_CHECK` が無い
- **THEN** `warn` に変数の名前が含まれ、終了コードは0

#### Scenario: 設定がある
- **WHEN** `~/.claude/settings.json` の `env` で `IMPECCABLE_NO_STALENESS_CHECK` が `"1"`
- **THEN** その項目は `ok`
