# Spec Delta

## MODIFIED Requirements

### Requirement: 検査項目
`uskn-harness doctor` は次を検査し、各項目を `ok` / `warn` / `fail` で報告しなければならない（MUST）。

- 環境の種類と環境の印
- 参照点の存在と向き先
- mise、node、jqの有無（閉じた環境では共有の置き場の記録）
- `deps.json` でピン止めしたnpmのCLIの版（閉じた環境では共有の置き場の記録）
- `~/.local/bin` の実行ファイルのsymlink（`uskn-harness` と `uskn-loop`）の存在と向き先
- `~/.claude/skills` の各symlinkの存在と向き先
- chezmoi管理の同名スキルとの衝突
- 各プラグインのsymlinkと `claude plugin validate` の結果
- サードパーティスキルの有無
- `~/.claude/CLAUDE.md` の管理印
- ユーザー層のsettings.jsonと、syncが書く値とのずれ
- `~/.local/bin` の通知のコマンドのsymlink（管理者の環境だけ）

#### Scenario: 健全な環境
- **WHEN** `sync` 直後に `doctor` を実行する
- **THEN** すべて `ok` で終了コード0

#### Scenario: 向き先が違う symlink
- **WHEN** `~/.claude/skills/commit` が別のパスを指すsymlink
- **THEN** その項目は `fail` で、終了コードは1

#### Scenario: ループのコマンドが無い
- **WHEN** `sync` のあとで `~/.local/bin/uskn-loop` を消してから `doctor` を実行する
- **THEN** その項目は `warn` で、`uskn-harness sync` の実行を促す

#### Scenario: 環境の種類の行
- **WHEN** 印の無いcheckoutで `doctor` を実行する
- **THEN** 報告に、環境の種類が `admin` であることを示す `ok` の行がある

### Requirement: 通知のコマンドの検査
管理者の環境の間、`doctor` は、`plugins/uskn-notify/bin/` の各コマンドについて、`~/.local/bin/<name>` の状態を報告しなければならない（MUST）。
そのコマンドを指すsymlinkなら `ok`、実ファイルなら `warn`（`conflict`）、無ければ `warn` とする。
閉じた環境では、この項目を報告しない。

#### Scenario: dotfiles のコピーが残っている
- **WHEN** 管理者の環境で、`~/.local/bin/claude-notify-hook` が実ファイル
- **THEN** `warn` にファイルのパスが含まれ、終了コードは0

#### Scenario: 閉じた環境
- **WHEN** 閉じた環境で、`~/.local/bin/claude-notify` が無い状態で `doctor` を実行する
- **THEN** 通知のコマンドの行は報告に現れない

### Requirement: サードパーティスキルの ref の確認
管理者の環境の間、`doctor` は、`via` が `skills` のサードパーティスキルごとに、lockファイルの `ref` とピンの差を報告しなければならない（MUST）。
同じなら `ok`、違うかlockの項目が `ref` を持たなければ `warn` とし、両方の値と `sync` の案内を含める。
lockに項目が無いときも `warn` とする。
閉じた環境での確認は、要件「共有の置き場の確認」が決める。

#### Scenario: ref の不一致
- **WHEN** 管理者の環境で、lockのgrillingの項目が `ref` を持たない
- **THEN** grillingは `warn` で、ピンの `ref` と `sync` の案内が含まれ、終了コードは0

#### Scenario: ピンと同じ
- **WHEN** 管理者の環境で、lockのgrillingの `ref` が `deps.json` と同じ
- **THEN** grillingは `ok`

## ADDED Requirements

### Requirement: 環境の印の検査
checkoutに環境の印があるとき、`doctor` は印を検査しなければならない（MUST）。
次のどれかに当たれば `fail` とし、当たった理由を含める。

- `kind` が `confined` でないか、印を読めない
- 印の持ち主のuidが0でない
- `doctor` を実行したOSのユーザーが、印に書ける

batsでは、比べるuidを環境変数 `USKN_MARKER_UID` で差し替える。syncとhookの判定は、この値で変わらない。

#### Scenario: 持ち主が root でない
- **WHEN** 実行したOSのユーザーが持ち主の印で `doctor` を実行する
- **THEN** 印の行は `fail` で、持ち主が理由に含まれ、終了コードは1

### Requirement: 閉じた環境の書き込みの検査
閉じた環境の間、`doctor` は、実行したOSのユーザーがcheckoutと共有の置き場に書けるかを報告しなければならない（MUST）。
どちらかに書けるときは `fail` とし、書けるパスを含める。
閉じた環境の守りは、エージェントがhookと道具を書き換えられないことに依るため。

#### Scenario: 書ける共有の置き場
- **WHEN** 閉じた環境で、共有の置き場が実行したOSのユーザーの持ち物
- **THEN** その行は `fail` で、共有の置き場のパスが含まれる

### Requirement: 共有の置き場の確認
閉じた環境の間、`doctor` は、共有の置き場の `installed.json` の版とrefを、`deps.json` のピンと項目ごとに比べなければならない（MUST）。
同じなら `ok`、違うか記録に無ければ `warn` とし、両方の値と、管理者が `install-shared` を実行する案内を含める。
`~/.claude/skills/<name>` が共有の置き場の `skills/<name>` を指さないときも `warn` とする。

#### Scenario: 古い textlint
- **WHEN** 閉じた環境で、記録のtextlintの版が `deps.json` より古い
- **THEN** textlintの行は `warn` で、両方の版と `install-shared` の案内が含まれ、終了コードは0

### Requirement: 持ち込まない端末別設定のキーの警告
閉じた環境の間、端末別設定がsandboxを緩めるキーを持つとき、`doctor` は `warn` を報告しなければならない（MUST）。
キーの範囲は、user-settingsの要件「閉じた環境で持ち込まない端末別設定のキー」と同じ。
`warn` には外すキーのパスと、そのキーをsyncが持ち込まないことを含める。

#### Scenario: 端末別設定の接続先
- **WHEN** 閉じた環境で、端末別設定の `sandbox.network.allowedDomains` にホストがある
- **THEN** `warn` に `sandbox.network.allowedDomains` が含まれ、終了コードは0

### Requirement: 閉じた環境で使えない sandbox-exec
閉じた環境の間、`sandbox-exec` を使えないとき、`doctor` は `fail` を報告しなければならない（MUST）。
使えないとは、OSがmacOSでないとき、またはPATHに `sandbox-exec` が無いときを言う。
`fail` には、hookがリポジトリのコードを動かさないことと、Linuxの閉じた環境が対象外であることを含める。

#### Scenario: Linux の閉じた環境
- **WHEN** 閉じた環境のLinuxで `doctor` を実行する
- **THEN** その行は `fail` で、終了コードは1

### Requirement: 参照点の移行の案内
管理者の環境の間、参照点がmanaged cloneで、開発用のcheckoutが別の場所にあるとき、`doctor` は `warn` を報告しなければならない（MUST）。
開発用のcheckoutの場所は、`~/.config/uskn-harness/dev-checkout` の1行、無ければ `~/repos/uskn-harness` である。
`warn` には、managed cloneを手で退け、開発用のcheckoutへのsymlinkに置き換える手順を含める。
`doctor` と `sync` は、参照点を置き換えてはならない（MUST NOT）。

#### Scenario: managed clone が残った開発機
- **WHEN** 参照点が実ディレクトリのcloneで、`~/.config/uskn-harness/dev-checkout` の指す場所にgitのcheckoutがある
- **THEN** `warn` に置き換えの手順が含まれ、参照点は変わらず、終了コードは0
