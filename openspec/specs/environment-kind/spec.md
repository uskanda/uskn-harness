# environment-kind Specification

## Purpose
ハーネスを導入する環境が、管理者の環境か閉じた環境かを決める規則。
環境の種類は、checkoutの直下にあるrootの持ち物の環境の印で決め、閉じた環境のOSのユーザーが書ける場所からは読まない。

## Requirements

### Requirement: 環境の印の置き場と書式
環境の印は、参照点が解決するcheckoutの直下のファイル `.uskn-environment` でなければならない（MUST）。
印は `key=value` の行から成る。空の行と `#` で始まる行は読み飛ばす。
キーは3つで、`kind` は環境の種類、`tools` は共有の置き場の絶対パス、`secrets` は秘密の置き場の絶対パスである。
`kind` の値は `confined` だけを使う。
`.gitignore` は `.uskn-environment` を持ち、印はリポジトリに入らない。

#### Scenario: 閉じた環境の印
- **WHEN** checkoutの直下の `.uskn-environment` が `kind=confined` と `tools=/opt/shared` の2行を持つ
- **THEN** 環境の種類は閉じた環境で、共有の置き場は `/opt/shared` になる

#### Scenario: git が追跡しない
- **WHEN** checkoutの直下に `.uskn-environment` を置いて `git status --porcelain` を実行する
- **THEN** 出力に `.uskn-environment` は現れない

### Requirement: 印の無い checkout
checkoutの直下に `.uskn-environment` が無いとき、ハーネスのコマンドとhookは、環境の種類を管理者の環境として扱わなければならない（MUST）。

#### Scenario: 開発機
- **WHEN** 印の無いcheckoutで `uskn-environment` を実行する
- **THEN** 出力は `admin` の1行

### Requirement: 正しくない印
`.uskn-environment` があり、`kind` が `confined` でないか、ファイルを読めないとき、ハーネスのコマンドとhookは、閉じた環境として扱わなければならない（MUST）。
印を置いた意図は、守りを強めることにあるため。

#### Scenario: 値の書き間違い
- **WHEN** `.uskn-environment` の `kind` が `confind`
- **THEN** `uskn-environment` の出力は `confined` で、doctorはその印を `fail` と報告する

### Requirement: 環境の種類を読む側
sync、doctor、`print-settings`、`sandbox-exclude`、`sandbox-allow-host`、hookは、環境の種類を印だけから決めなければならない（MUST）。
引数、環境変数、ユーザー層のファイルで、環境の種類を変えてはならない（MUST NOT）。
閉じた環境のOSのユーザーは、それらを書き換えられるため。

#### Scenario: 環境変数で変えようとする
- **WHEN** `kind=confined` の印のあるcheckoutで、環境変数を変えて `uskn-environment` を実行する
- **THEN** 出力は `confined` のまま

### Requirement: 環境の種類を出すコマンド
プラグインは、環境の種類を1行で出すコマンド `uskn-environment` を `bin/` に持たなければならない（MUST）。
出力は `admin` か `confined` で、終了コードは0とする。
スキルは、pushのような環境の種類で振る舞いの変わる手順の前に、このコマンドを使う。

#### Scenario: 閉じた環境
- **WHEN** `kind=confined` の印のあるcheckoutのプラグインで、`uskn-environment` を実行する
- **THEN** 出力は `confined` の1行で、終了コードは0
