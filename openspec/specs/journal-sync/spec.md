# journal-sync Specification

## Purpose
journal をセッション終了時に sessions repo へ確定し、push によってマシン間で共有する。ネットワークが無い端末でも commit だけは残し、次回に追いつく。

## Requirements

### Requirement: SessionEnd で commit と push
SessionEnd hook は journal を最終更新しなければならない（MUST）。
続けて `~/.ai-sessions` で `git add` と `git commit` を実行し、`git push` を最大 20 秒で試みる。
push の失敗は無視し、次回の SessionEnd で再試行する。変更が無ければ commit しない。

#### Scenario: オフライン
- **WHEN** push が失敗する
- **THEN** commit は残り、終了コードは 0

### Requirement: sessions repo の配置
`sync` は `~/.ai-sessions` が無ければ `deps.json` の `repos.sessions.url` から clone しなければならない（MUST）。
`doctor` はその存在と、git リポジトリであることを検査する。

#### Scenario: 新しいマシン
- **WHEN** `~/.ai-sessions` が無い状態で `sync` を実行する
- **THEN** clone され、`doctor` が ok を報告する
