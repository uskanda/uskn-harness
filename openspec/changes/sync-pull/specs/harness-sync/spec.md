## ADDED Requirements

### Requirement: checkout の更新
`sync` は導入を始める前に、ハーネスの checkout を fast-forward しなければならない（MUST）。
実行するのは次のすべてを満たすときに限る。git の作業ツリーであること。HEAD が branch を指し、その branch に upstream があること。追跡ファイルと未追跡ファイルのどちらにも変更が無いこと。
merge と rebase は行わない（MUST NOT）。fast-forward できないときは何もしない。
満たさない条件があるときは、その理由を 1 行で報告して更新を飛ばし、導入は続行する。

`--tools`、`--remove`、`--no-pull` のときは更新しない（MUST NOT）。`--dry-run` は予定を出力するだけで実行しない。
ネットワークや認証で待ち続けないよう、時間の上限と非対話の設定を付ける。更新の失敗はそのまま報告し、導入は続行する。

#### Scenario: 別マシンで遅れている
- **WHEN** clean な checkout で `sync` を実行し、upstream のほうが進んでいる
- **THEN** checkout は upstream まで fast-forward され、更新が報告される

#### Scenario: 作業中の checkout
- **WHEN** 変更を抱えた checkout で `sync` を実行する
- **THEN** 更新は行われない。未コミットの変更があると報告し、導入を続ける

#### Scenario: fast-forward できない
- **WHEN** checkout が upstream と分岐している
- **THEN** 更新は行われず、失敗が報告され、終了コードは 0

#### Scenario: CI
- **WHEN** `sync --tools` を実行する
- **THEN** 更新は行われない

### Requirement: 更新後の再実行
更新で HEAD が動いたとき、`sync` は新しい `bin/uskn-harness` を同じ引数で実行し直さなければならない（MUST）。
走行中のスクリプトが入れ替わることを避け、残りの導入を新しい版のロジックで行うため。
再実行は 1 回に限り、実行し直した側は checkout を更新しない。

#### Scenario: 更新があった
- **WHEN** `sync` の更新で HEAD が動く
- **THEN** 新しい `bin/uskn-harness` が同じ引数で実行され、そちらは更新を試みずに導入を続ける

#### Scenario: 更新が無かった
- **WHEN** checkout が既に upstream と同じ
- **THEN** 実行し直さず、そのまま導入を続ける
