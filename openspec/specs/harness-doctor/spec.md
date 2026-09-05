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

### Requirement: sessions リポジトリの検査
`doctor` は `~/.ai-sessions` がgitリポジトリであることを検査し、無ければ `warn` としなければならない（MUST）。

#### Scenario: 欠落
- **WHEN** `~/.ai-sessions` が無い
- **THEN** `warn` と `sync` の案内

### Requirement: npm global CLI の版の確認
`doctor` は `deps.json` の `clis` の各項目について、入っている版がピンと一致すれば `ok`、無いか異なれば `warn` を報告しなければならない（MUST）。

#### Scenario: 版の不一致
- **WHEN** textlint 15.0.0が入っていて `deps.json` は15.8.0を指す
- **THEN** `warn` に両方の版が含まれる
