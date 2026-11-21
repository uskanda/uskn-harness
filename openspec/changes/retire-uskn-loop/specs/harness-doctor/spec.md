## MODIFIED Requirements

### Requirement: 検査項目
`uskn-harness doctor` は次を検査し、各項目を `ok` / `warn` / `fail` で報告しなければならない（MUST）。

- 参照点の存在と向き先
- mise、node、jqの有無
- `deps.json` でピン止めしたnpmのCLIの版
- `~/.local/bin/uskn-harness` のsymlinkの存在と向き先
- 廃止した `~/.local/bin/uskn-loop` のsymlinkの残り
- `~/.claude/skills` の各symlinkの存在と向き先
- chezmoi管理の同名スキルとの衝突
- 各プラグインのsymlinkと `claude plugin validate` の結果
- サードパーティスキルの有無
- `~/.claude/CLAUDE.md` の管理印
- ユーザー層のsettings.jsonと、syncが書く値とのずれ
- `~/.local/bin` の通知のコマンドのsymlink

#### Scenario: 健全な環境
- **WHEN** `sync` 直後に `doctor` を実行する
- **THEN** すべて `ok` で終了コード0

#### Scenario: 向き先が違う symlink
- **WHEN** `~/.claude/skills/commit` が別のパスを指すsymlink
- **THEN** その項目は `fail` で、終了コードは1

#### Scenario: ループのコマンドが無い
- **WHEN** `~/.local/bin/uskn-loop` の無い端末で `doctor` を実行する
- **THEN** ループのコマンドについての `warn` は出ない

#### Scenario: 廃止したループのコマンドが残っている
- **WHEN** ハーネスの中を指す `~/.local/bin/uskn-loop` が残っている端末で `doctor` を実行する
- **THEN** その項目は `warn` で、`uskn-harness sync` の実行を促す
