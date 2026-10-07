## MODIFIED Requirements

### Requirement: 検査項目
`uskn-harness doctor` は次を検査し、各項目を `ok` / `warn` / `fail` で報告しなければならない（MUST）。

- 参照点の存在と向き先
- mise、node、jqの有無
- `deps.json` でピン止めしたnpmのCLIの版
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

### Requirement: 鮮度警告の設定の確認
環境変数 `IMPECCABLE_NO_STALENESS_CHECK=1` がどこにも設定されていないとき、`doctor` は `warn` を報告しなければならない（MUST）。
確かめる場所は、`~/.claude/settings.json` の `env` と、`doctor` 自身の環境の2つ。
この設定は設定断片が持ち、`sync` がliveへ書く。

#### Scenario: 設定が無い
- **WHEN** `~/.claude/settings.json` の `env` に `IMPECCABLE_NO_STALENESS_CHECK` が無い
- **THEN** `warn` に変数の名前と `sync` の案内が含まれ、終了コードは0

#### Scenario: 設定がある
- **WHEN** `~/.claude/settings.json` の `env` で `IMPECCABLE_NO_STALENESS_CHECK` が `"1"`
- **THEN** その項目は `ok`

## ADDED Requirements

### Requirement: ユーザー層の設定の検査
`doctor` は、syncが今の状態から書くはずの値を求め、liveの `~/.claude/settings.json` と比べなければならない（MUST）。
求め方は、合成のマージ、3方向の片付け、effortの消去をsyncと同じ規則で行う。
一致すれば `ok`、違えば `warn` と報告し、`warn` には違うキーのパスと `sync` の案内を含める。
liveか端末別設定がJSONとして読めないときは `warn` とし、ファイルの名前を含める。

#### Scenario: /effort の後
- **WHEN** 端末で `/effort` を使い、liveの `modelSettings` に `effortLevel` が書かれている
- **THEN** `warn` に `modelSettings` のパスと `sync` の案内が含まれ、終了コードは0

#### Scenario: sync の直後
- **WHEN** `sync` の直後に `doctor` を実行する
- **THEN** その項目は `ok`

### Requirement: 通知のコマンドの検査
`doctor` は、`plugins/uskn-notify/bin/` の各コマンドについて、`~/.local/bin/<name>` の状態を報告しなければならない（MUST）。
そのコマンドを指すsymlinkなら `ok`、実ファイルなら `warn`（`conflict`）、無ければ `warn` とする。

#### Scenario: dotfiles のコピーが残っている
- **WHEN** `~/.local/bin/claude-notify-hook` が実ファイル
- **THEN** `warn` にファイルのパスが含まれ、終了コードは0
