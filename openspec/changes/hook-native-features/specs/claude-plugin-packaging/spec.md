## ADDED Requirements

### Requirement: hook の起動条件
`hooks.json` は、対象のファイルが決まっているhookに `if` を付けなければならない（MUST）。
textlint-checkとterms-checkは、Writeに `Write(**/*.md)`、Editに `Edit(**/*.md)` を付ける。
grilling-guardは、Writeに `Write(**/openspec/changes/**)`、Editに `Edit(**/openspec/changes/**)` を付ける。
`if` は1つの規則しか持てないので、ツールごとにmatcherを分け、そのツールの規則を1つずつ書く。
write-guard、bash-guard、SessionStartとStopのhookには `if` を付けない。

#### Scenario: Markdown 以外の編集
- **WHEN** `if` を解するClaude Codeで、作業ディレクトリの `src/a.ts` をEditする
- **THEN** textlint-checkとterms-checkは起動しない

#### Scenario: hooks.json の構成
- **WHEN** `hooks.json` のPostToolUseを読む
- **THEN** textlint-checkとterms-checkは、matcherが `Write` の項目と `Edit` の項目に1つずつある
- **AND** `if` は、`Write` の項目では `Write(**/*.md)`、`Edit` の項目では `Edit(**/*.md)`

### Requirement: if を解さない版での絞り込み
`if` で絞るhookのスクリプトは、同じ条件を自分で確かめなければならない（MUST）。
`if` を解さない版のClaude Codeでは、hookがすべての書き込みで起動するからである。

#### Scenario: 古い版での Markdown 以外の編集
- **WHEN** `src/a.ts` のEditの入力を、textlint-checkとterms-checkのスクリプトに直接渡す
- **THEN** 2つのスクリプトは何も出力せず、終了コード0で終わる

### Requirement: スキル向けの短いコマンド
プラグインは `bin/` に、スキルがBashで呼ぶ補助スクリプトの短いコマンドを持たなければならない（MUST）。
`uskn-repo-context` は `session-start.sh` を、`uskn-terms-check` は `terms-check.sh` を、同じ引数で実行する。
終了コードと出力は、元のスクリプトと同じにする。
プラグインがsymlinkを通して読み込まれていても動く。

#### Scenario: ブランチモデルの取得
- **WHEN** gitリポジトリの中で `uskn-repo-context --plain branches` を実行する
- **THEN** `session-start.sh --plain branches` と同じ4行が出力される

#### Scenario: 用語の検査
- **WHEN** 実在しない名前を含む文書に `uskn-terms-check` を実行する
- **THEN** 指摘が出力され、終了コードは1

### Requirement: スキルは短いコマンドで呼ぶ
スキルは、`session-start.sh` と `terms-check.sh` を `hooks/scripts/` の長いパスで呼んではならない（MUST NOT）。
代わりに `uskn-repo-context` と `uskn-terms-check` を使う。

#### Scenario: スキルの監査
- **WHEN** `skills/` の下の `SKILL.md` を `hooks/scripts/session-start.sh` と `hooks/scripts/terms-check.sh` で検索する
- **THEN** 一致しない
