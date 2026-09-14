# journal-sync Specification

## Purpose
journalをセッション終了時に、各端末のローカルgitにあるsessionsリポジトリへ確定する。pushはせず、ネットワークに出ない。

## Requirements

### Requirement: sessions リポジトリの配置
`sync` は `~/.ai-sessions` が無ければ、`git init` で空のgitリポジトリを作らなければならない（MUST）。
cloneは行わない。`doctor` はその存在と、gitリポジトリであることを検査する。

#### Scenario: 新しいマシン
- **WHEN** `~/.ai-sessions` が無い状態で `sync` を実行する
- **THEN** 空のgitリポジトリが作られ、ネットワークには出ず、`doctor` がokを報告する

### Requirement: SessionEnd で commit
SessionEnd hookはjournalを最終更新しなければならない（MUST）。
続けて `~/.ai-sessions` で `git add` と `git commit` を実行する。変更が無ければcommitしない。
hookはpush、pull、fetchを行ってはならない（MUST NOT）。remoteが設定されていても同じ。

#### Scenario: remoteがある
- **WHEN** `~/.ai-sessions` に `origin` が設定された状態でSessionEndが発火する
- **THEN** journalはcommitされ、`origin` の履歴は変わらず、終了コードは0

#### Scenario: 変更なし
- **WHEN** 前回のSessionEnd以降journalが変わっていない
- **THEN** 新しいcommitは作られない
