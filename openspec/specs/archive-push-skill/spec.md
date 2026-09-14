# archive-push-skill Specification

## Purpose

変更のarchive、main specsへの同期、検証、コミット、pushを、ユーザーの1コマンドでまとめて行うスキル。決まった答えの確認は省き、判断が要る場面だけユーザーに尋ねる。

## Requirements

### Requirement: ユーザーだけが呼べる
`archive-push` はエージェントの判断で呼ばれてはならない（MUST NOT）。
ユーザーが `/archive-push` と入力したときだけ動く。

#### Scenario: エージェントの自発的な呼び出し
- **WHEN** 実装を終えたエージェントが、自分の判断で `archive-push` を呼ぼうとする
- **THEN** `archive-push` は呼べない

### Requirement: 1回に1つの変更を扱う
`archive-push` は1回の実行で1つの変更だけを扱わなければならない（MUST）。
引数に変更の名前が無く、対象を1つに決められないとき、`archive-push` はユーザーに尋ねなければならない（MUST）。

#### Scenario: 名前の指定
- **WHEN** ユーザーが `/archive-push add-x` を実行する
- **THEN** 変更 `add-x` だけをarchiveする

#### Scenario: 候補が複数
- **WHEN** 進行中の変更が2つあり、ユーザーが引数なしで `/archive-push` を実行する
- **THEN** どちらをarchiveするかをユーザーに尋ね、答えを待つ

### Requirement: 無関係な変更のコミット範囲を尋ねる
対象と無関係な未コミットの変更があるとき、`archive-push` は何かを動かす前にコミットの範囲をユーザーに尋ねなければならない（MUST）。
選択肢は、archive分だけをコミットするか、全部をコミットするかの2つとする。
無関係な変更が無いとき、`archive-push` はこの確認を求めてはならない（MUST NOT）。

#### Scenario: 別の作業が残っている
- **WHEN** 対象と関係の無いファイルに未コミットの変更がある
- **THEN** archive分だけか全部かを尋ね、答えるまでarchiveを始めない

#### Scenario: archive分だけを選ぶ
- **WHEN** ユーザーがarchive分だけを選ぶ
- **THEN** 無関係な変更は未コミットのまま残り、報告で列挙される

### Requirement: 未コミットの実装は別のコミットにする
対象の変更の `tasks.md` かproposalのImpactに名前のあるファイルは、対象と関係のある変更として扱う。
そうしたファイルが未コミットのとき、`archive-push` はarchiveのコミットより前に、それらを実装のコミットとしてコミットしなければならない（MUST）。

#### Scenario: 実装が未コミット
- **WHEN** `tasks.md` が名指しする `skills/x/SKILL.md` が未コミットのまま `/archive-push add-x` を実行する
- **THEN** 範囲の確認は出ず、実装のコミットの後にarchiveのコミットが1つできる

### Requirement: 変更を伴う未完了の項目があれば止まる
コード、文書、specの変更を伴う未完了の項目が `tasks.md` にあるとき、`archive-push` はarchiveせずに止まらなければならない（MUST）。

#### Scenario: 未実装の項目
- **WHEN** `tasks.md` に「`README.md` に1行足す」が未チェックで残っている
- **THEN** その項目を報告して止まり、archiveとコミットをしない

### Requirement: コマンドで確かめられる項目は実行する
エージェントがコマンドで確かめられる未完了の項目があるとき、`archive-push` はそのコマンドを実行しなければならない（MUST）。
コマンドが通れば完了とみなし、失敗すれば止まる。

#### Scenario: 確認のコマンドが通る
- **WHEN** 未チェックの項目が「`uskn-harness sync --dry-run` の計画にリンクが出ることを確認する」で、実行した結果にリンクが出る
- **THEN** その項目を完了とみなして進む

#### Scenario: 確認のコマンドが失敗する
- **WHEN** 同じ項目を実行した結果にリンクが出ない
- **THEN** 結果を報告して止まり、archiveしない

### Requirement: 実行できない確認の項目は完了とみなす
エージェントが実行できず、コードの変更を伴わない未完了の項目があるとき、`archive-push` はその項目を完了とみなさなければならない（MUST）。
ユーザーによる確認がその例である。

#### Scenario: ユーザーによる動作確認
- **WHEN** 未完了の項目が「別の端末でユーザーが動作を確認する」だけである
- **THEN** 止まらずにarchiveへ進む

### Requirement: 完了とみなした項目に注記する
未完了の項目を完了とみなしたとき、`archive-push` はその項目を、archiveする前にチェック済みとしなければならない（MUST）。
その行の末尾には「（archive-pushで完了とみなした）」と書き足す。

#### Scenario: archiveに残る記録
- **WHEN** 項目「別の端末でユーザーが動作を確認する」を完了とみなしてarchiveする
- **THEN** archiveされた `tasks.md` のその行は `- [x]` で始まり、「（archive-pushで完了とみなした）」で終わる

### Requirement: 分け方に迷う項目は尋ねる
未完了の項目が変更を伴うかを決められないとき、`archive-push` は推測で完了とみなしてはならない（MUST NOT）。
そうした項目は1つずつユーザーへ尋ねる。

#### Scenario: どちらとも読める項目
- **WHEN** 未チェックの項目が「ユーザーと相談して文言を決める」である
- **THEN** その項目を完了とみなしてよいかをユーザーに尋ね、答えを待つ

### Requirement: archiveの前に検証する
`archive-push` はarchiveの前に検証規約を走らせなければならない（MUST）。
失敗したとき、`archive-push` は作業ツリーを変えずに止まらなければならない（MUST）。

#### Scenario: 実装側の失敗
- **WHEN** archiveの前の `make verify` が失敗する
- **THEN** 変更のディレクトリ、main specs、`tasks.md` がどれも変わらないまま、失敗を報告して止まる

### Requirement: specを確認なしで同期する
対象の変更がdelta specを持つとき、`archive-push` は同期の可否を尋ねずにmain specsへ同期してからarchiveしなければならない（MUST）。

#### Scenario: 差分がある
- **WHEN** 変更がmain specsに未反映のdelta specを持つ
- **THEN** 確認を求めずにmain specsへ同期し、変更を `openspec/changes/archive/` へ移す

### Requirement: archiveの後に検証する
`archive-push` はarchiveの後、コミットの前に検証規約を走らせなければならない（MUST）。
失敗したとき、`archive-push` はコミットせずに、作業ツリーに残ったものを報告して止まらなければならない（MUST）。

#### Scenario: 同期後の失敗
- **WHEN** archiveの後の `make verify` が失敗する
- **THEN** コミットとpushをせず、移した変更と同期したmain specsが未コミットで残っていると報告する

### Requirement: 1つのコミットにまとめる
`archive-push` はarchiveの結果を1つのコミットにまとめなければならない（MUST）。
要約行は、delta specを同期したときは「`<name>`をarchiveし、main specsに反映」、同期するspecが無いときは「`<name>`をarchive」とする。

#### Scenario: specを同期した変更
- **WHEN** 変更 `add-x` をarchiveし、能力 `x` を同期した
- **THEN** 要約行が「add-xをarchiveし、main specsに反映」のコミットが1つでき、本文に `x` が並ぶ

### Requirement: pushする
コミットの後、`archive-push` は `push` スキルでpushしなければならない（MUST）。
保護ブランチでの確認やpushの拒否の扱いは `push` スキルに従う。

#### Scenario: 保護されていないブランチ
- **WHEN** 現在のブランチが保護ブランチでない
- **THEN** コミットがoriginへpushされ、報告にpushしたブランチとコミットが載る
