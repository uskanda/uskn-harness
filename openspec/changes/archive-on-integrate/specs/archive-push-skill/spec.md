## REMOVED Requirements

### Requirement: ユーザーだけが呼べる
**Reason**: 統合の操作の前に、`pr` と `push` が `archive-push` を呼ぶため（issue #19 Q2）。
**Migration**: ユーザーは今までどおり `/archive-push` と打てる。エージェントが自分の判断で呼ぶことの制限は、要件「呼ぶのはユーザーか統合の操作をするスキル」に移す。

## ADDED Requirements

### Requirement: 呼ぶのはユーザーか統合の操作をするスキル
`archive-push` は、ユーザーが `/archive-push` と入力したとき、または統合の操作をするスキル（`pr` と `push`）が呼んだときに動かなければならない（MUST）。
`archive-push` のfrontmatterは `disable-model-invocation` を持ってはならない（MUST NOT）。

#### Scenario: ユーザーの入力
- **WHEN** ユーザーが `/archive-push add-x` と入力する
- **THEN** 変更 `add-x` のarchiveが始まる

#### Scenario: pr からの呼び出し
- **WHEN** `pr` が統合の操作の前に、未archiveの変更 `add-x` を見つける
- **THEN** `pr` は `archive-push add-x` を呼べる

### Requirement: archive保留の宣言のある変更を選ばない
引数に変更の名前が無いとき、`archive-push` はarchive保留の宣言（`.archive-later`）のある変更を候補にしてはならない（MUST NOT）。

#### Scenario: 宣言のある変更と無い変更
- **WHEN** 進行中の変更が `add-x` と `add-y` の2つで、`add-y` に `.archive-later` があり、引数なしで `archive-push` を実行する
- **THEN** 尋ねずに `add-x` だけをarchiveする
