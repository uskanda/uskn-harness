## ADDED Requirements

### Requirement: Co-Authored-By トレーラ
`commit` は各コミットメッセージの末尾に `Co-Authored-By: Claude <noreply@anthropic.com>` トレーラを付けなければならない（MUST）。
付ける条件は無く、本体のセッションから呼んだときも、forkした先で実行したときも同じ。

#### Scenario: セッション内のコミット
- **WHEN** `/commit` を実行する
- **THEN** 各コミットの末尾に `Co-Authored-By: Claude <noreply@anthropic.com>` がある

#### Scenario: 別のスキルから呼んだコミット
- **WHEN** `push` が未コミットの変更を `commit` でコミットする
- **THEN** そのコミットにも同じトレーラがある

## REMOVED Requirements

### Requirement: Session トレーラ
**Reason**: トレーラの値でjournalを引く `recall` を削除する。セッションjournalの仕組みごと廃止する。
**Migration**: 新しいコミットには付けない。既存のコミットのトレーラはそのまま残す。コミットの経緯は、コミットの本文と変更のアーカイブで確かめる。
