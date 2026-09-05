# journal-sync Specification

## Purpose
journalをセッション終了時にsessionsリポジトリへ確定し、pushによってマシン間で共有する。ネットワークが無い端末でもcommitだけは残し、次回に追いつく。

## Requirements

### Requirement: SessionEnd で commit と push
SessionEnd hookはjournalを最終更新しなければならない（MUST）。
続けて `~/.ai-sessions` で `git add` と `git commit` を実行し、`git push` を最大20秒で試みる。
pushの失敗は無視し、次回のSessionEndで再試行する。変更が無ければcommitしない。

#### Scenario: オフライン
- **WHEN** pushが失敗する
- **THEN** commitは残り、終了コードは0

### Requirement: sessions リポジトリの配置
`sync` は `~/.ai-sessions` が無ければ `deps.json` の `repos.sessions.url` からcloneしなければならない（MUST）。
`doctor` はその存在と、gitリポジトリであることを検査する。

#### Scenario: 新しいマシン
- **WHEN** `~/.ai-sessions` が無い状態で `sync` を実行する
- **THEN** cloneされ、`doctor` がokを報告する
