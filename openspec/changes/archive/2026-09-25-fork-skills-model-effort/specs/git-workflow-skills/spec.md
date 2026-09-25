## ADDED Requirements

### Requirement: commit の実行の形
`commit` はforkで動き、`model: sonnet` と `effort: low` を使わなければならない（MUST）。

#### Scenario: ユーザーが直接打つ
- **WHEN** ユーザーが `/commit` を打つ
- **THEN** sonnetのsubagentが会話の文脈を持たずにコミットし、報告だけが返る

### Requirement: commit の引数
`commit` は引数を `[課題ID] [指示の文]` として読まなければならない（MUST）。
最初の語が数字か、`#` の付いた数字のとき、それを課題IDとし、各要約行の先頭に `#<番号>` と空白を付ける。
残りの文は、コミットの順番、分け方、要約行、本文を縛る指示として従う。
引数が無いときは、課題IDも追加の指示も無い動きでコミットする。

#### Scenario: 課題IDだけ
- **WHEN** `/commit 123` を実行する
- **THEN** 各要約行が `#123` と空白で始まる

#### Scenario: 指示の文
- **WHEN** `archive-push` が、archiveのパスを1つのコミットにして要約行を指定する指示の文を引数で渡す
- **THEN** archiveのパスは、指定された要約行を持つ1つのコミットになる

#### Scenario: 引数なし
- **WHEN** 引数なしで `/commit` を実行する
- **THEN** 変更の目的だけでコミットを分け、要約行に番号を付けない

### Requirement: commit の分割
`commit` は変更を目的ごとに1〜5個のコミットに分けなければならない（MUST）。
目的が1つの変更は、1つのコミットにする。

#### Scenario: 目的が1つの変更
- **WHEN** 1つの目的のための実装、テスト、specが未コミットで残っている
- **THEN** コミットは1つできる

## MODIFIED Requirements

### Requirement: Session トレーラ
`commit` は各コミットメッセージの末尾に `Session: <sid8>` トレーラを付けなければならない（MUST）。
`<sid8>` はセッションIDの先頭8文字で、`${CLAUDE_SESSION_ID}` から得る。
セッションIDを得られないときだけ、トレーラを付けない。

#### Scenario: セッション内のコミット
- **WHEN** IDの先頭が `3f2a9c1d` のセッションから `/commit` を実行する
- **THEN** 各コミットの末尾に `Session: 3f2a9c1d` がある

#### Scenario: 別のスキルから呼んだコミット
- **WHEN** `push` から呼ばれたforkの `commit` がコミットする
- **THEN** トレーラの値は、`push` を実行したセッションのIDの先頭8文字になる
