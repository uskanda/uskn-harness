# harness-doctor Specification

## Purpose
ハーネスの導入状態を検査し、壊れている箇所と原因を人が読める形で示す。run_once や CI からも使えるよう、問題があれば非ゼロで終わる。

## Requirements

### Requirement: 検査項目
`uskn-harness doctor` は次を検査し、各項目を `ok` / `warn` / `fail` で報告しなければならない（MUST）。

- 参照点の存在と向き先
- mise、node、jq の有無
- `deps.json` でピン止めした npm の CLI の版
- `~/.claude/skills` の各 symlink の存在と向き先
- chezmoi 管理の同名スキルとの衝突
- プラグイン symlink と `claude plugin validate` の結果
- サードパーティスキルの有無
- `~/.claude/CLAUDE.md` の管理印

#### Scenario: 健全な環境
- **WHEN** `sync` 直後に `doctor` を実行する
- **THEN** すべて `ok` で終了コード 0

#### Scenario: 向き先が違う symlink
- **WHEN** `~/.claude/skills/commit` が別のパスを指す symlink
- **THEN** その項目は `fail` で、終了コードは 1

### Requirement: 終了コード
`fail` が 1 つでもあれば終了コード 1、`warn` のみなら 0 で終わらなければならない（MUST）。

#### Scenario: 衝突だけがある
- **WHEN** chezmoi 管理の同名スキルによる `conflict` だけが検出される
- **THEN** その項目は `warn` で、終了コードは 0

### Requirement: 書き込みをしない
`doctor` はファイルシステムを変更してはならない（MUST NOT）。

#### Scenario: 読み取り専用
- **WHEN** `doctor` を実行する
- **THEN** `~/.claude` と `~/.local` の内容は実行前後で同一

### Requirement: schema の検査
`doctor` は `~/.local/share/openspec/schemas/uskn` の存在と向き先を他の symlink と同じ規則で検査しなければならない（MUST）。

#### Scenario: 欠落
- **WHEN** symlink が無い
- **THEN** `warn` として報告され、`sync` の実行が案内される

### Requirement: sessions repo の検査
`doctor` は `~/.ai-sessions` が git リポジトリであることを検査し、無ければ `warn` としなければならない（MUST）。

#### Scenario: 欠落
- **WHEN** `~/.ai-sessions` が無い
- **THEN** `warn` と `sync` の案内
