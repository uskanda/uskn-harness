# Spec Delta

## Purpose

管理者が、ピンどおりの道具とサードパーティスキルを、閉じた環境のOSのユーザーの書けない共有の置き場へ入れるコマンド。
閉じた環境のsyncは導入をせず、この置き場へlinkを張る。

## ADDED Requirements

### Requirement: 共有の置き場への導入
`uskn-harness install-shared <dir>` は、`<dir>` の下に道具を導入しなければならない（MUST）。
導入するのは、`deps.json` の `runtimes` のnodeとjq、`clis` のうち `global` が真の項目、`skills` のうち `mode` が `reference` の項目である。
nodeとjqとCLIの実行ファイルへのsymlinkは `<dir>/bin/` に置き、サードパーティスキルは `<dir>/skills/<name>/` に置く。
版とrefは `deps.json` のピンに従う。

#### Scenario: 空の置き場
- **WHEN** 空のディレクトリ `<dir>` で `uskn-harness install-shared <dir>` を実行する
- **THEN** `<dir>/bin/textlint` と `<dir>/bin/openspec` が実行でき、`<dir>/skills/grilling/SKILL.md` がある

### Requirement: 導入の記録
`install-shared` は、導入した項目の版とrefを `<dir>/installed.json` に書かなければならない（MUST）。
記録の版とrefが `deps.json` と同じ項目は、入れ直してはならない（MUST NOT）。

#### Scenario: 2 回目
- **WHEN** 導入の直後に、同じ `<dir>` で `install-shared` を再実行する
- **THEN** 何も入れ直さず、各項目が `ok` と報告される

#### Scenario: ピンを上げた
- **WHEN** `deps.json` のtextlintの版を上げて `install-shared` を実行する
- **THEN** textlintだけが入れ直され、`updated` と報告され、記録の版が新しい値になる

### Requirement: ユーザー層と持ち主に触れない
`install-shared` は、ユーザー層（`~/.claude`、`~/.local/bin`、端末別設定）に書いてはならない（MUST NOT）。
`<dir>` の持ち主とモードを変えてはならない（MUST NOT）。
閉じた環境のOSのユーザーが書けないようにするのは、端末の土台の仕事である。

#### Scenario: 管理者が実行する
- **WHEN** 管理者が `install-shared <dir>` を実行する
- **THEN** 管理者の `~/.claude/skills` と `~/.claude/settings.json` は、実行の前後で変わらない

### Requirement: dry-run と失敗の終了コード
`install-shared --dry-run <dir>` は、ファイルシステムを変えず、予定の操作を1行ずつ出力しなければならない（MUST）。
導入の手順が失敗したときは、残りの手順を続け、終了コード1で終わらなければならない（MUST）。
`<dir>` を渡さないときは、何もせず終了コード2で終える。

#### Scenario: ネットワークが無い
- **WHEN** ネットワークの無い端末で `install-shared <dir>` を実行する
- **THEN** 失敗した手順の数が標準エラーに出て、終了コードは1

#### Scenario: 置き場を渡さない
- **WHEN** `uskn-harness install-shared` を引数なしで実行する
- **THEN** 何も作られず、終了コードは2
