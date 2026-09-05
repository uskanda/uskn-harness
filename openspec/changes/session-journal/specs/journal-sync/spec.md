## Purpose

journal をセッション終了時に sessions repo へ確定し、マシン間で共有する。

## ADDED Requirements

### Requirement: SessionEnd で commit と push
SessionEnd hook は journal を最終更新し、`~/.ai-sessions` で `git add` と `git commit` を行い、`git push` を最大 20 秒で試みなければならない（MUST）。push の失敗は無視し、次回の SessionEnd で再試行する。変更が無ければ commit しない。

#### Scenario: オフライン
- **WHEN** push が失敗する
- **THEN** commit は残り、終了コードは 0

### Requirement: sessions repo の配置
`sync` は `~/.ai-sessions` が無ければ `deps.json` の `repos.sessions.url` から clone し、`doctor` はその存在と git リポジトリであることを検査しなければならない（MUST）。

#### Scenario: 新しいマシン
- **WHEN** `~/.ai-sessions` が無い状態で `sync` を実行する
- **THEN** clone され、`doctor` が ok を報告する
